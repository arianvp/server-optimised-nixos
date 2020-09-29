{ config ? ./config/example.nix
, nixpkgs ? (import ./nix/sources.nix).nixpkgs
, hostPkgs ? import nixpkgs { }
, pkgs ? import nixpkgs {
    overlays = map import [ ./overlays/systemd.nix  ./overlays/image-tools.nix ];
  }
}:
{
  inherit pkgs;
  inherit hostPkgs;
  it =
    import ./lib/eval-config.nix {
      inherit pkgs;
      inherit hostPkgs;
      inherit (pkgs) lib;
      modules = [
        ./config/example.nix
      ];
    };
}
