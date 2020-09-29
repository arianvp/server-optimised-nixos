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

  network = pkgs.writeText "0-main.network" ''
    [Match]
    Name=ens*
    [Network]
    DHCP=yes
  '';
  # Fancy little hack to not need global path to systemd. However is it
  # actually fancy? How do we "reload" this?
  init = pkgs.writeShellScript "init" ''
    SYSTEMD_UNIT_PATH=${config.system.build.units}: exec ${pkgs.systemd}/lib/systemd/systemd
  '';

  # Notes about initrd:
  # nixpkgs kmod is patched to read from /run/current-system/kernel-modules
  # echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe

  initrdfs = pkgs.linkFarm "initrdfs" [
    { name = "etc/initrd-release"; path = "${initrdRelease}"; }
    { name = "init"; path = "${init}"; }
    # { name = "etc/systemd/system"; path = "${units}"; }
    { name = "etc/modules-load.d/modules.conf"; path = "${modules}"; }
    { name = "etc/systemd/network/0-main.network"; path = "${network}"; }


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
      default = [ "e1000" "autofs4 " "squashfs" "virtio_net" "virtio_rng" "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_balloon" "virtio_console" ];
    };

    kernelModules = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };
  config = {
    systemd = {
      sockets = {
        systemd-networkd.wantedBy = [ "sockets.target" ];
      };
      services = {
        systemd-networkd = {
          # TODO: in stage-2 this is multi-user.target heh
          wantedBy = [ "initrd.target" ];
          serviceConfig.BindReadOnlyPaths = [
            # "${pkgs.systemd}/lib/systemd/network:/etc/systemd/network"
          ];
        };
        systemd-networkd-wait-online.wantedBy = [ "network-online.target" ];
        emergency.serviceConfig = {
          ExecStart = [ "" "${pkgs.busybox}/bin/ash" ];
          Environment = "PATH=${pkgs.busybox}/bin:${pkgs.systemd}/bin:${pkgs.utillinuxMinimal}/bin";
        };
        initrd-cleanup.enable = false;
        systemd-update-done.enable = false;
        systemd-udevd.serviceConfig.BindReadOnlyPaths = [
          "${pkgs.systemd}/lib/udev:/etc/udev"
          "${pkgs.systemd}/lib/systemd/network:/etc/systemd/network"
        ];

        systemd-sysctld.serviceConfig.BindReadOnlyPaths = [
          "${pkgs.systemd}/lib/sysctl.d:/etc/sysctl.d"
        ];

        systemd-sysusers.serviceConfig.BindReadOnlyPaths =
          "${pkgs.systemd}/lib/sysusers.d:/etc/sysusers.d";
        systemd-tmpfiles-setup.serviceConfig.BindReadOnlyPaths =
          "${pkgs.systemd}/lib/tmpfiles.d:/etc/tmpfiles.d";
        systemd-tmpfiles-setup-dev.serviceConfig.BindReadOnlyPaths = "${pkgs.systemd}/lib/tmpfiles.d:/etc/tmpfiles.d";

        modprobe-init = {
          wantedBy = [ "sysinit.target" ];
          unitConfig.DefaultDependencies = false;
          serviceConfig.ExecStart = ''${pkgs.busybox}/bin/ash -c "echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe'';
        };

      };
    };

    kernel.params = [
      "root=/dev/vda"
      "console=ttyS0"
      "panic=-1"
      "systemd.log_level=debug"
      "rd.systemd.log_level=debug"
      "udev.log-priority=debug"
      "rd.udev.log-priority=debug"
    ];
    system.build.init = init;
    system.build.initrd = pkgs.makeInitrd  { storeContents = initrdfs; };
    # system.build.initrdfs = initrdfs;
    # system.build.units = units;
    # system.build.modulesClosure = modulesClosure;
  };
}
