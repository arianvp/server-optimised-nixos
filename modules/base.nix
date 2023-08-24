{ pkgs, config, lib, ... }:
{
  # boot.loader.systemd-boot.enable = true;
  boot.bootspec.enable = true;
  boot.loader.external.enable = true;
  boot.loader.external.installHook = pkgs.writeScript "install" ''
    echo would install
  '';
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.initrd.systemd.repart.enable = true;
  # we shouldn't disable this for non-containers. Systemd ships the unit anyway and already
  # has a ConditionVirtualization=container clause
  systemd.services.console-getty.enable = true;
  services.getty.autologinUser = "root";

  networking.useNetworkd = true;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  boot.initrd.availableKernelModules = [
    "overlay"
  ];
  boot.initrd.supportedFilesystems = [
    "erofs"
  ];

  documentation.nixos.enable = false;
  system.disableInstallerTools = true;
  nix.channel.enable = false;
  nix.settings.experimental-features = [
    "nix-command" "flakes"
  ];
  nix.enable = true;
  # Lets see what happens
  # system.activationScripts.users = lib.mkForce "";
  # system.activationScripts.hashes = lib.mkForce "";
  systemd.additionalUpstreamSystemUnits = [
  ];
  systemd.package = pkgs.systemd-sysusers;

  # TODO: Make nicer. should run earlier?
  systemd.services.nix-path-registration = {
    requiredBy = [ "multi-user.target" ];
    script = ''
    ${config.nix.package}/bin/nix-store --load-db < /nix/store/.nix-path-registration
    '';
  };

  boot.initrd.systemd = {
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

  fileSystems = {
    # "/nix/store" = { device = "/usr/store"; fsType = "none"; options = [ "bind" ]; depends = [ "/usr" ]; };
  };
  system.stateVersion = "23.05";
}

