/*
Implementation of the stage-1 init using systemd
*/
{ pkgs, lib, config, ... }:
let
  cfg = config.stage-1;
  initrdRelease = pkgs.writeText "initrd-release" ''
    NAME=NixOS
    ID=nixos
    VERSION="1"
    VERSION_CODENAME="coreos"
    VERSION_ID="1"
    PRETTY_NAME="NixOS"
    HOME_URL="https://nixos.org/"
    SUPPORT_URL="https://nixos.org/nixos/support.html"
    BUG_REPORT_URL="https://github.com/NixOS/nixpkgs/issues"
  '';

  modulesClosure = pkgs.makeModulesClosure {
    rootModules = cfg.kernelModules ++ cfg.availableKernelModules;
    kernel = config.system.build.kernel; # TODO configurable?
    firmware = config.system.build.kernel;
    allowMissing = false;
  };

  emergency =
    pkgs.writeText "emergency.service" ''
      [Unit]
      Description=Emergency Shell
      Documentation=man:sulogin(8)
      DefaultDependencies=no
      Conflicts=shutdown.target
      Conflicts=rescue.service
      Before=shutdown.target
      Before=rescue.service

      [Service]
      ExecStart=${pkgs.busybox}/bin/ash
      Environment=PATH=${pkgs.busybox}/bin:${pkgs.systemd_}/bin:${pkgs.utillinuxMinimal}/bin
      Type=idle
      StandardInput=tty-force
      StandardOutput=inherit
      StandardError=inherit
      KillMode=process
      IgnoreSIGPIPE=no
      SendSIGHUP=yes
    '';


  modprobe-init =
    pkgs.writeText "modprobe-init.service" ''
      [Unit]
      DefaultDependencies=no
      Before=sysinit.target
      [Service]
      ExecStart=${pkgs.busybox}/bin/ash -c "echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe"
    '';
  ownUnits = pkgs.linkFarm "own-units" [
    { name = "initrd-cleanup.service"; path = "/dev/null"; } # NOTE: Just here to get us in emergency shell in right place
    { name = "systemd-update-done.service"; path = "/dev/null"; } # TODO see how we get it to work
    { name = "emergency.service"; path = "${emergency}"; }
    { name = "modprobe-init.service"; path = "${modprobe-init}"; }
    { name = "sysinit.target.wants/modprobe-init.service"; path = "${modprobe-init}"; }
  ];

  units = pkgs.symlinkJoin {
    name = "units";
    ignoreCollisions = true;
    paths = [
      # NOTE: User-provided inputs have presedence over systemd-provided ones
      ownUnits
      # NOTE: systemd should already read from rootlibdir correctly :)

      # NOTE: SYSTEMD_UNIT_PATH= can also be set :). So we do not need global paths;
      # at least for _units_
      # "${pkgs.systemd_}/lib/systemd/system"
    ];
  };

  modules = pkgs.writeText "modules.conf" (pkgs.lib.strings.intersperse "\n" cfg.kernelModules);

  # Notes about initrd:
  # nixpkgs kmod is patched to read from /run/current-system/kernel-modules
  # echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe

  initrdfs = pkgs.linkFarm "initrdfs" [
    { name = "etc/initrd-release"; path = "${initrdRelease}"; }
    { name = "init"; path = "${pkgs.systemd_}/lib/systemd/systemd"; }
    { name = "etc/systemd/system"; path = "${units}"; }
    { name = "etc/modules-load.d/modules.conf"; path = "${modules}"; }
    { name = "etc/udev"; path = "${pkgs.systemd_}/lib/udev"; }
    { name = "lib/modules"; path = "${modulesClosure}/lib/modules"; }
    # No firmware for now
    # { name = "lib/firmware"; path = "${modulesClosure}/lib/firmware"; }
    { name = "sbin/modprobe"; path = "${pkgs.kmod}/bin/modprobe"; }
  ];

in
{
  imports = [ ./systemd.nix ];
  options.stage-1 = {
    compressor = lib.options.mkOption {
      type = lib.types.str;
      internal = true;
      default = "gzip -9n";
      example = "xz";
    };

    availableKernelModules = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "autofs4 " "squashfs" "virtio_net" "virtio_rng" "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_balloon" "virtio_console" ];
    };

    kernelModules = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };

  };
  config = {
    systemd = {
      targets."sysinit".wants = [
        "modprobe-init.service"
      ];
      services = {
        "initrd-cleanup".enable = false;
        "systemd-update-done".enable = false;
        "modprobe-init" = {
          unitConfig = {
            DefaultDependencies = false;
          };
          serviceConfig.ExecStart = ''${pkgs.busybox}/bin/ash -c "echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe'';
        };

      };
    };

    kernel.params = [
      "rd.systemd.unit=initrd.target" # not needed in 245. See NEWS
      "root=/dev/vda"
      "systemd.log_level=debug"
      "rd.systemd.log_level=debug"
      "udev.log-priority=debug"
      "rd.udev.log-priority=debug"
    ];
    system.build.initrd = (pkgs.callPackage ../lib/make-initrd.nix) { storeContents = initrdfs; };
    # system.build.initrdfs = initrdfs;
    # system.build.units = units;
    # system.build.modulesClosure = modulesClosure;
  };
}
