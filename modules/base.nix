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
  nix.enable = false;
  # Lets see what happens
  # system.activationScripts.users = lib.mkForce "";
  # system.activationScripts.hashes = lib.mkForce "";
  systemd.additionalUpstreamSystemUnits = [
  ];
  systemd.package = pkgs.systemd-sysusers;



  fileSystems = {
    # "/" =          { device = "none"; fsType = "tmpfs"; options = ["mode=0755" ]; };
    # This _should_ be picked up by gpt-auto-generator?
    # "/usr"       = { device = "/dev/disk/by-partlabel/usr"; fsType = "erofs"; };
    "/nix/store" = { device = "/usr/store"; fsType = "none"; options = ["bind"]; depends = ["/usr"]; };
  };
  system.stateVersion = "23.05";
}
