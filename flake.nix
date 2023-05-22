{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
    nixosModules.repart = { config, pkgs, lib, ... }:
      let
        cfg = config.systemd.repart;
        writeDefinition = name: partitionConfig: pkgs.writeText
          "${name}.conf"
          (lib.generators.toINI { } { Partition = partitionConfig; });

        listOfDefinitions = lib.mapAttrsToList
          writeDefinition
          (lib.filterAttrs (k: _: !(lib.hasPrefix "_" k)) cfg.partitions);

        # Create a directory in the store that contains a copy of all definition
        # files. This is then passed to systemd-repart in the initrd so it can access
        # the definition files after the sysroot has been mounted but before
        # activation. This needs a hard copy of the files and not just symlinks
        # because otherwise the files do not show up in the sysroot.
        definitionsDirectory = pkgs.runCommand "systemd-repart-definitions" { } ''
          mkdir -p $out
          ${(lib.concatStringsSep "\n"
            (map (pkg: "cp ${pkg} $out/${pkg.name}") listOfDefinitions)
          )}
        '';
      in
      # TODO: Upstream
      { config.system.build.partitionDefinitions = definitionsDirectory; };

    nixosModules.base = {
      boot.loader.systemd-boot.enable = true;
      boot.initrd.systemd.enable = true;
      boot.initrd.systemd.repart.enable = true;
      system.stateVersion = "23.05";
    };

    nixosModules.system = { config, ... }: {
      systemd.repart.partitions = {
        "10-esp" = {
          Type = "esp";
          Format = "vfat";
          CopyFiles = "${config.systemd.package}/lib/systemd/boot/efi/systemd-bootaa64.efi";
        };
        "20-root" = {
          Type = "root";
        };
      };
      fileSystems = {
        "/".device = "/dev/disk/by-partlabel/root";
        "/boot".device = "/dev/disk/by-partlabel/esp";
      };
    };

    nixosModules.image = { config, pkgs, lib, ... }: {
      options = { };
      config.system.build.image = pkgs.runCommand "image"
        {
          nativeBuildInputs = [
            pkgs.systemd
            pkgs.dosfstools
            pkgs.mtools
            pkgs.e2fsprogs
          ];
        }
        # TODO: specify size
        ''
          export TMPDIR=$(mktemp -d)
          export TEMP=$TMPDIR
          export TMP=$TMPDIR
          systemd-repart \
            --empty=create \
            --size=2G \
            --definitions ${config.system.build.partitionDefinitions} \
            $out
        '';
    };

    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        self.nixosModules.base
        self.nixosModules.system
        self.nixosModules.repart
        self.nixosModules.image
      ];
    };
    packages.aarch64-linux.default = self.nixosConfigurations.default.config.system.build.image;
  };
}
