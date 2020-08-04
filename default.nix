{ config ? ./config/example.nix
, nixpkgs ? (import ./nix/sources.nix).nixpkgs
, pkgs ? import ../nixos/nixpkgs {
    overlays = map import [ ./overlays/systemd.nix  ./overlays/image-tools.nix ];
  }
}:
{
  inherit pkgs;
  it =
    import ./lib/eval-config.nix {
      inherit pkgs;
      inherit (pkgs) lib;
      modules = [
        ./config/example.nix
      ];
    };
}
