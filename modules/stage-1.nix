/*
Implementation of the stage-1 init using systemd
*/
{ pkgs, lib, config, ... }:
with import ../../nixpkgs/nixos/modules/system/boot/systemd-unit-options.nix { inherit config lib; };
with import ../../nixpkgs/nixos/modules/system/boot/systemd-lib.nix { inherit config lib pkgs; };
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
  ];

  modulesClosure = pkgs.makeModulesClosure {
    rootModules = cfg.kernelModules;
    kernel = config.system.build.kernel; # TODO configuralbe?
    firmware = config.system.build.kernel;
    allowMissing = false;
  };

  specialFSTypes = [ "proc" "sysfs" "tmpfs" "ramfs" "devtmpfs" "devpts" ];

  init = pkgs.writeShellScript "init" ''
    ${pkgs.busybox}/bin/mkdir -p /lib
    ${pkgs.busybox}/bin/ln -s ${modulesClosure}/lib/modules /lib/modules
    ${pkgs.busybox}/bin/ln -s ${modulesClosure}/lib/firmware /lib/firmware
    exec ${pkgs.systemd}/lib/systemd/systemd
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
    ] ++ (map (unit: { symlink = "/etc/systemd/system/${unit}"; object = "${pkgs.systemd}/example/systemd/system/${unit}"; }) upstreamUnits) ++ [ { symlink = "/etc/systemd/system/sysroot.mount"; object = "${sysroot}"; } ];
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
    kernel.params = [];
    system.build.initrd = initrd;
  };
}
