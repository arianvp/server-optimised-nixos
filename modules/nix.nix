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

  boot.initrd.availableKernelModules = [ "overlay" "virtio" ];

  fileSystems."/nix/.ro-store" = {
    device = "nix-store";
    fsType = "virtiofs";
    options = [ "x-initrd.mount" "ro" ];
    neededForBoot = true;
  };

  fileSystems."/nix/store" = {
    device = "overlay";
    fsType = "overlay";
    options = [
      "x-initrd.mount" "rw" "lowerdir=/sysroot/nix/.ro-store,upperdir=/sysroot/nix/.rw-store/upper,workdir=/sysroot/nix/.rw-store/work"
      "x-systemd.requires=rw-store.service"
    ];
    neededForBoot = true;
  };

  boot.initrd.systemd = {
    services.rw-store = {
      unitConfig = {
        DefaultDependencies = false;
        RequiresMountsFor = "/sysroot";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/bin/mkdir -p -m 0755 /sysroot/nix/.rw-store/upper /sysroot/nix/.rw-store/work";
      };
    };
  };
}
