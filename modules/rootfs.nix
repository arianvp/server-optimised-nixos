{ pkgs, ... }:
{
  config.systemd.build.image = makeEFI {
    esp = pkgs.makeVFAT {
      size = 1024 * 1024 * 1024;
      files = {};
    };

    # TODO also use "files" for "makeSquashFs"
    root = pkgs.makeSquashfs {
      storeContents = [ pkgs.systemd ];
    };
  }
