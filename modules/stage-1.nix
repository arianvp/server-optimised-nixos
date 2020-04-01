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

  upstreamUnits = [
    "autovt@.service"
    "swap.target"
    "local-fs-pre.target"
    "local-fs.target"
    "sysinit.target"
    "timers.target" "paths.target" "sockets.target"
    "basic.target" "rescue.service" "rescue.target"

    "emergency.target"

    "systemd-journald.service"
    "systemd-journald.socket"
    "systemd-journald-audit.socket"
    "systemd-journald-dev-log.socket"

    "initrd-root-device.target"
    "initrd-root-fs.target"
    "initrd-parse-etc.service"

    "initrd-fs.target"
    "initrd.target"

    "initrd-cleanup.service"
    "initrd-udevadm-cleanup-db.service"
    "initrd-switch-root.target"
    "initrd-switch-root.service"

    "sockets.target.wants"

  ];

  modulesClosure = pkgs.makeModulesClosure {
    rootModules = cfg.kernelModules;
    kernel = config.system.build.kernel; # TODO configuralbe?
    firmware = config.system.build.kernel;
    allowMissing = false;
  };

  init = pkgs.writeShellScript "init" ''
    ${pkgs.busybox}/bin/mkdir -p /lib
    ${pkgs.busybox}/bin/ln -s ${modulesClosure}/lib/modules /lib/modules
    ${pkgs.busybox}/bin/ln -s ${modulesClosure}/lib/firmware /lib/firmware
    exec ${pkgs.systemd}/lib/systemd/systemd
  '';

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
    Environment=PATH=${pkgs.busybox}/bin:${pkgs.systemd}/bin
    Type=idle
    StandardInput=tty-force
    StandardOutput=inherit
    StandardError=inherit
    KillMode=process
    IgnoreSIGPIPE=no
    SendSIGHUP=yes
  '';
  sysroot =
    pkgs.writeText "sysroot.mount" ''
      [Mount]
      What=/dev/vda
      Where=/sysroot
      Type=squashfs
    '';


  initrd = pkgs.makeInitrd {
    inherit (cfg) compressor;
    contents = [
      { symlink = "/etc/initrd-release"; object = "${initrdRelease}"; }
      { symlink = "/init"; object = "${init}"; }
    ] ++ (map (unit: { symlink = "/etc/systemd/system/${unit}"; object = "${pkgs.systemd}/example/systemd/system/${unit}"; }) upstreamUnits) ++ [ { symlink = "/etc/systemd/system/sysroot.mount"; object = "${sysroot}"; } { symlink = "/etc/systemd/system/emergency.service"; object="${emergency}";} ];
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
      default = [ "autofs4 "];
    };

    systemd.units = lib.options.mkOption {
      default = {};
      type = with lib.types; attrsOf (
        submodule (
          { name, config, ... }: {
            options = concreteUnitOptions;
            config = {
              unit = lib.mkDefault (makeUnit name config);
            };
          }
        )
      );
    };
  };
  config = {
    kernel.params = [ "rd.systemd.unit=initrd.target" "systemd.journald.forward_to_console=1" ]; # not needed in 245. See NEWS
    system.build.initrd = initrd;
  };
}
