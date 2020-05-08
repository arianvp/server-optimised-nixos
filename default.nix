{ config ? ./config/example.nix
, nixpkgs ? (import ./nix/sources.nix).nixpkgs
, pkgs ? import nixpkgs {
    overlays = map import [ ./overlays/systemd.nix ];
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
