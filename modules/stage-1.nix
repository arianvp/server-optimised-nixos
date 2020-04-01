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
    rootModules = cfg.kernelModules;
    kernel = config.system.build.kernel; # TODO configuralbe?
    firmware = config.system.build.kernel;
    allowMissing = false;
  };

  init = pkgs.writeShellScript "init" ''
    ${pkgs.busybox}/bin/echo "Welcome to Server-optimised NixOS"
    ${pkgs.busybox}/bin/mkdir -p /lib
    ${pkgs.busybox}/bin/ln -s ${modulesClosure}/lib/modules /lib/modules
    ${pkgs.busybox}/bin/ln -s ${modulesClosure}/lib/firmware /lib/firmware
    exec ${pkgs.systemd}/lib/systemd/systemd
  '';

  emergency =
    pkgs.writeTextDir "emergency.service" ''
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
      Environment=PATH=${pkgs.busybox}/bin:${pkgs.systemd}/bin:${pkgs.utillinuxMinimal}/bin
      Type=idle
      StandardInput=tty-force
      StandardOutput=inherit
      StandardError=inherit
      KillMode=process
      IgnoreSIGPIPE=no
      SendSIGHUP=yes
    '';
  sysroot =
    pkgs.writeTextDir "sysroot.mount" ''
      [Mount]
      What=/dev/vda
      Where=/sysroot
      Type=squashfs
    '';

  units = pkgs.buildEnv {
    name = "units";
    ignoreCollisions = true;
    paths = [
      emergency #NOTE should override
      sysroot
      "${pkgs.systemd}/example/systemd/system"
    ];
  };

  # TODO we shouldn't load all the modules. just the ones we need
  modules = pkgs.writeText "modules.conf" (pkgs.lib.strings.intersperse "\n" cfg.kernelModules);

  initrd = pkgs.makeInitrd {
    inherit (cfg) compressor;
    contents = [
      { symlink = "/etc/initrd-release"; object = "${initrdRelease}"; }
      { symlink = "/init"; object = "${init}"; }
      { symlink = "/etc/systemd/system"; object = "${units}"; }
      { symlink = "/etc/modules-load.d/modules.conf"; object = "${modules}"; }
    ];
  };
in
{
  options.stage-1 = {
    compressor = lib.options.mkOption {
      type = lib.types.str;
      internal = true;
      default = "gzip -9n";
      example = "xz";
    };

    kernelModules = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "autofs4" "squashfs" "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_balloon" "virtio_console" ];
    };

  };
  config = {
    kernel.params = [ "rd.systemd.unit=initrd.target" "systemd.journald.forward_to_console=1" ]; # not needed in 245. See NEWS
    system.build.initrd = initrd;
  };
}
