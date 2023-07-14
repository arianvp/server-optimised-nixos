{
  description = "A very basic flake";

  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

  nixConfig = {
    trusted-substituters = [ "https://cache.garnix.io" ];
    substituters = [ "https://cache.garnix.io" ];
    trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };

  outputs = { self, nixpkgs }: {

    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    overlays.systemd = import ./overlays/systemd.nix;

    nixosModules = {
      base = ./modules/base.nix;
      image = ./modules/image.nix;
      system = { config, ... }: {
        system.stateVersion = "23.05";
        fileSystems = {
          # TODO gpt-auto-generator already takes care of these two. not needed.
          "/".device = "/dev/disk/by-partlabel/root-arm64";
          "/".fsType = "ext4";
          "/boot".device = "/dev/disk/by-partlabel/esp";
        };
      };
    };

    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        { nixpkgs.overlays = [ self.overlays.systemd ]; }
        self.nixosModules.base
        self.nixosModules.system
        self.nixosModules.image
      ];
    };

    packages.aarch64-linux = rec {
      inherit
        (self.nixosConfigurations.default.config.system.build)
        kernel
        uki
        closure
        toplevel
        systemd-tools
        image
        nspawn
        bootStage2;
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
