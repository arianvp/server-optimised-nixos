{ pkgs, config, lib, ... }:
{
  imports = [./nix.nix ];
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

  nix.enable = true;

  # Lets see what happens
  # system.activationScripts.users = lib.mkForce "";
  # system.activationScripts.hashes = lib.mkForce "";
  systemd.additionalUpstreamSystemUnits = [
  ];
  systemd.package = pkgs.systemd-sysusers;

 
  system.stateVersion = "23.05";
}

