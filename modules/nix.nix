{ config, pkgs, lib, ... }: {
  nix.channel.enable = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # TODO: Make nicer. should run earlier?
  systemd.services.nix-path-registration = lib.mkIf config.nix.enable {
    requiredBy = [ "multi-user.target" ];
    script = ''
      ${config.nix.package}/bin/nix-store --load-db < /nix/store/.nix-path-registration
    '';
  };

  boot.initrd.systemd = lib.mkIf config.nix.enable {
    mounts = [{
      where = "/sysroot/nix/store";
      what = "overlay";
      type = "overlay";
      options = "lowerdir=/sysroot/usr/store,upperdir=/sysroot/nix/.rw-store/store,workdir=/sysroot/nix/.rw-store/work";
      wantedBy = [ "initrd-fs.target" ];
      before = [ "initrd-fs.target" ];
      requires = [ "rw-store.service" ];
      after = [ "rw-store.service" "sysroot-usr.mount" ];
      unitConfig.RequiresMountsFor = "/sysroot/usr/store";
    }];
    services.rw-store = {
      unitConfig = {
        DefaultDependencies = false;
        RequiresMountsFor = "/sysroot/nix/.rw-store";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/bin/mkdir -p -m 0755 /sysroot/nix/.rw-store/store /sysroot/nix/.rw-store/work /sysroot/nix/store";
      };
    };
  };
}
