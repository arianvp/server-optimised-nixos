{ pkgs, hostPkgs, lib,  modules, check ? true}:
let
  commonConfig = rec {
    _file = ./eval-config.nix;
    key = _file;
    _module = {
      args = { inherit pkgs hostPkgs; };
      inherit check;
    };
  };
in
  lib.modules.evalModules {
    modules = modules ++ [commonConfig];
  }

