{ pkgs, config, ... }:
let
  squashfs = pkgs.makeSquashfs {
    storeContents = pkgs.systemd;
  };
in
{
  config.system.build.image = pkgs.makeEFI {
    esp = pkgs.makeVFAT {
      size = 1024 * 1024 * 1024;
      files = {};
    };
    root = squashfs;
  };
}
