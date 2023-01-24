{
  description = "SONOS";

  outputs = { self, nixpkgs }: {
    nixosConfigurations.base = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./modules/base.nix ];
    };
  };
}
