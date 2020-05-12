/*
Implementation of the stage-1 init using systemdG
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

  modules = pkgs.writeText "modules.conf" (pkgs.lib.strings.intersperse "\n" cfg.kernelModules);

  # Fancy little hack to not need global path to systemd. However is it
  # actually fancy? How do we "reload" this?
  init = pkgs.writeShellScript "init" ''
    SYSTEMD_UNIT_PATH=${config.system.build.units}: exec ${pkgs.systemd_}/lib/systemd/systemd
  '';

  # Notes about initrd:
  # nixpkgs kmod is patched to read from /run/current-system/kernel-modules
  # echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe

  initrdfs = pkgs.linkFarm "initrdfs" [
    { name = "etc/initrd-release"; path = "${initrdRelease}"; }
    { name = "init"; path = "${init}"; }
    # { name = "etc/systemd/system"; path = "${units}"; }
    { name = "etc/modules-load.d/modules.conf"; path = "${modules}"; }


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
        "emergency".serviceConfig = {
          ExecStart = [ "" "${pkgs.busybox}/bin/ash" ];
          Environment = "PATH=${pkgs.busybox}/bin:${pkgs.systemd_}/bin:${pkgs.utillinuxMinimal}/bin";
        };
        "initrd-cleanup".enable = false;
        "systemd-update-done".enable = false;
        "systemd-udevd".serviceConfig = {
          # for .hwdb and .rules files link files
          BindReadOnlyPaths = [ "${pkgs.systemd_}/lib/udev:/etc/udev" "/etc/systemd/network:${pkgs.systemd_}/lib/systemd/network:/etc/systemd/network" ];
        };

        "systemd-sysuserd".serviceConfig = {
          BindReadOnlyPaths = "${pkgs.systemd_}/lib/sysusers.d:/etc/sysusers.d";
        };

        "systemd-tmpfiles-setup".serviceConfig = {
          BindReadOnlyPaths = "${pkgs.systemd_}/lib/tmpfiles.d:/etc/tmpfiles.d";
        };
        "systemd-tmpfiles-setup-dev".serviceConfig = {
          BindReadOnlyPaths = "${pkgs.systemd_}/lib/tmpfiles.d:/etc/tmpfiles.d";
        };

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
    system.build.init = init;
    system.build.initrd = (pkgs.callPackage ../lib/make-initrd.nix) { storeContents = initrdfs; };
    # system.build.initrdfs = initrdfs;
    # system.build.units = units;
    # system.build.modulesClosure = modulesClosure;
  };
}
