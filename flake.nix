{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:arianvp/nixpkgs/gpt-auto";

  nixConfig = {
    extra-trusted-substituters = "https://cache.garnix.io";
    extra-substituters = "https://cache.garnix.io";
    extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
  };

  outputs = { self, nixpkgs }: {

    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    overlays.systemd = import ./overlays/systemd.nix;

    nixosModules = {
      base = ./modules/base.nix;
      image = ./modules/image.nix;
      etc = ./modules/etc.nix;
    };

    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        { nixpkgs.overlays = [ self.overlays.systemd ]; }
        self.nixosModules.base
        self.nixosModules.image
        self.nixosModules.etc
      ];
    };

    packages.aarch64-linux = rec {
      inherit
        (self.nixosConfigurations.default.config.system.build)
        toplevel
        image;
        # nspawn;
      default = toplevel;
    };

    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
    packages.aarch64-darwin.runvf = nixpkgs.legacyPackages.aarch64-darwin.swiftPackages.callPackage ./runvf { };

    devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
      name = "shell";
      nativeBuildInputs = [ ];
    };

  };
}
