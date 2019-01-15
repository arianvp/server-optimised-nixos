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

  sysroot = 
    pkgs.writeText "sysroot.mount"
    ''
    [Mount]
    What=/dev/vda
    Where=/sysroot
    Type=squashfs
    '';


  initrd = pkgs.makeInitrd {
    inherit (cfg) compressor;
    contents = [
      { symlink = "/etc/initrd-release"; object = "${initrdRelease}"; }
      { symlink = "/init";               object = "${pkgs.systemd}/lib/systemd/systemd"; }
    ] ++ (map (unit: { symlink = "/etc/systemd/system/${unit}"; object = "${pkgs.systemd}/example/systemd/system/${unit}"; }) upstreamUnits) ++
    [{ symlink = "/etc/systemd/system/sysroot.mount"; object = "${sysroot}"; } ];
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

    systemd.units = lib.options.mkOption {
      default = {};
      type = with lib.types; attrsOf (submodule (
        {name, config, ...}: {
          options = concreteUnitOptions;
          config = {
            unit = lib.mkDefault (makeUnit name config);
          };
        }
      ));
    };
  };
  config = {
    kernel.params = [ "rd.systemd.unit=initrd.target" ];
    # initrd.kernelModules = [ "autofs4" ];
    system.build.initrd = initrd;
  };
}
