{
  fileSystems = {
    "/nix/.ro-store" = {
      device = "nix-store";
      fsType = "virtiofs";
      options = [ "ro" ];
      neededForBoot = true;
    };
    "/nix/store" = {
      overlay = {
        lowerdir = [ "/nix/.ro-store" ];
        upperdir = "/nix/.rw-store/upper";
        workdir = "/nix/.rw-store/work";
      };
      neededForBoot = true;
    };
  };

    /*systemd.services.nix-path-registration = lib.mkIf config.nix.enable {
      requiredBy = [ "multi-user.target" ];
      script = ''
      ${config.nix.package}/bin/nix-store --load-db < /nix/store/.nix-path-registration
      '';
      };*/
}
