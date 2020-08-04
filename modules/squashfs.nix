{ pkgs, config, ... }:
let
  cfg = config.system.build;
  squashfs = pkgs.makeSquashfs {
    storeContents = pkgs.writeText "hey" "yo";
  };
in
{
  config.system.build.verity = pkgs.makeVerity squashfs;
  config.system.build.squashfs = squashfs;
}
