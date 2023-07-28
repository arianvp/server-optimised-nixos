{ pkgs, config, lib, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.bootspec.enable = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.initrd.systemd.repart.enable = true;
  # we shouldn't disable this for non-containers. Systemd ships the unit anyway and already
  # has a ConditionVirtualization=container clause
  systemd.services.console-getty.enable = true;
  services.getty.autologinUser = "root";

  networking.useNetworkd = true;

  systemd.repart.enable = true;
  systemd.repart.partitions.root = {
    Type = "root-${pkgs.stdenv.hostPlatform.linuxArch}"; 
    Format = "ext4";
  };

  # system.stateVersion = "23.05";
  fileSystems = {
    # TODO gpt-auto-generator already takes care of these two. not needed. But nixos insists. I think a udev rule is missing
    "/" = {
      device = "/dev/disk/by-partlabel/root-${pkgs.stdenv.hostPlatform.linuxArch}";
      fsType = "ext4";
      options = [ "x-systemd.growfs" ];
    };
  };
}
