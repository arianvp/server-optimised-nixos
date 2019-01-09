{ config ? ./config/example.nix
, nixpkgs ? <nixpkgs>
}:
let
  pkgs = import nixpkgs {};
  commonConfig = {
    _module = {
      args.pkgs = pkgs;
      check = true;
    };
  };
  system = pkgs.lib.modules.evalModules {
    modules = [ config commonConfig ];
  };
in
  system.config
