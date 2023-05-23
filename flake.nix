{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    nixosModules = {
      base = ./modules/base.nix;
      image = ./modules/image.nix;
      system = { config, ... }: {
        system.stateVersion = "23.05";
        fileSystems = {
          # TODO gpt-auto-generator already takes care of these two. not needed.
          "/".device = "/dev/disk/by-partlabel/root";
          "/boot".device = "/dev/disk/by-partlabel/esp";
        };
      };
    };

    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        { nixpkgs.overlays = [ (import ./overlays/systemd.nix) ]; }
        self.nixosModules.base
        self.nixosModules.system
        self.nixosModules.image
      ];
    };
    packages.aarch64-linux.default = self.nixosConfigurations.default.config.system.build.image;
  };
}
