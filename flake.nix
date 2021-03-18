{
  description = "A very basic flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = nixpkgs.lib.attrValues self.overlays;
          };
        in
          {
            packages.systemd = pkgs.systemd;
          }
    ) // {
      overlays = {
        systemd = (import ./overlays/systemd.nix);
        image-tools = (import ./overlays/image-tools.nix);
      };

      nixosModules = {
      };

      nixosConfiguration = nixpkgs.lib.modules.evalModules {
        modules = self.nixosModule;
      };
    };
}
