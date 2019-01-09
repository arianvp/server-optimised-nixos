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


  units = lib.attrsets.mapAttrsToList (k: v: { symlink = "/etc/systemd/system/${k}"; object = "${v.unit}/${k}"; }) cfg.systemd.units;

  # We use systemd as an initrd
  initrd = pkgs.makeInitrd {
    inherit (cfg.initrd) compressor;
    # TODO: systemd closure is kinda embarisingly big. maybe not most suited for a stage-1
    contents = [
      { symlink = "/init"; object = "${pkgs.systemd}/lib/systemd";  }
      { symlink = "/etc/initrd-release"; object = "${initrdRelease}"; }
    ]  ++ units;
    # TODO upstream systemd units like default.target
    # TODO check for "enabled" and for "wantedBy"
  };
in
{
  imports = [ ./squashfs.nix ];
  options.stage-1 = {
    initrd.compressor = lib.options.mkOption {
      type = lib.types.str;
      internal = true;
      default = "gzip -9n";
      example = "xz";
    };
    systemd.units = lib.options.mkOption {
      default = {};
      description = ''
        The list of units present in the initrd
      '';
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
    system.build.initrd = initrd;
  };
}
