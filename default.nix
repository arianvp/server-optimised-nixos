{ config ? ./config/example.nix
, lib ? import <nixpkgs/lib>
, pkgs ? import <nixpkgs> {}
}:
import ./lib/eval-config.nix {
  inherit pkgs lib;
  modules = [
    ./config/example.nix
  ];
}
