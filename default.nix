{ module ? ./modules/example.nix,
  pkgs ? import <nixpkgs> {}
}:
let
  lib = import ../nixpkgs/lib;
  system = lib.modules.evalModules {
    check = true;
    modules = [ module  { _module.args.pkgs = pkgs; }];
  };
in
  system.config
