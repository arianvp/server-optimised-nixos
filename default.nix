{ config ? ./config/example.nix
, pkgs ? import <nixpkgs> {}
}:
import ./lib/eval-config.nix {
  inherit pkgs;
  inherit (pkgs) lib;
  modules = [
    ./config/example.nix
  ];
}
