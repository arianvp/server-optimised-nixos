{ config ? ./config/example.nix
, pkgs ? import (import ./nix/sources.nix).nixpkgs {
  overlays = map import [ ./overlays/systemd.nix ];
  }
}:
import ./lib/eval-config.nix {
  inherit pkgs;
  inherit (pkgs) lib;
  modules = [
    ./config/example.nix
  ];
}
