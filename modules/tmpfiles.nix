{ config, pkgs, lib, ...}:
with lib;
{
  systemd.tmpfiles = mkOption {
    type = types.loaOf (types.submodule { name, config, ...}: {
      type = lib.types.enum [
        "f"
        "F"
        "w"
        "d"
        "D"
        "e"
        "v"
        "V"
        "Q"
        "p"
        "L"
        "c"
        "b"
        "p+"
        "L+"
        "c+"
        "b+"
        "C"
        "x"
        "X"
        "r"
        "R"
        "z"
        "Z"
        "t"
        "T"
        "h"
        "H"
        "a"
        "A"
        "a+"
        "A+"
      ];
    });
  };
}
