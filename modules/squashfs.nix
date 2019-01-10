{ pkgs, config, ... }:
let 
  cfg = config.system.build;
  makeSquashfs = storeContents: pkgs.callPackage ../lib/make-squashfs.nix { inherit storeContents; };
in
{
  config.system.build.squashfs = makeSquashfs {
    storeContents = pkgs.writeText "hey" "yo";
  };
}
