{ pkgs, config, lib, ... }:
{
  # boot.loader.systemd-boot.enable = true;
  boot.initrd.supportedFilesystems = [
    "ext4"
    "overlay"
    "squashfs"
  ];
  boot.initrd.availableKernelModules = [
    "af_packet" # systemd-networkd
    "dm_mod"
    "dm_verity"
    "e1000"
    "virtio_balloon"
    "virtio_blk"
    "virtio_console"
    "virtio_mmio"
    "virtio_net"
    "virtio_pci"
    "virtio_rng"
    "virtio_scsi"
  ];
  boot.kernelParams = [ "console=hvc0" ];
  # TODO: systemd kmod_setup will already load these modules
  boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];
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

  boot.postBootCommands =
    ''
      # After booting, register the contents of the Nix store
      # in the Nix database in the tmpfs.
      echo "Registering Nix store paths.."
      ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration

      # nixos-rebuild also requires a "system" profile and an
      # /etc/NIXOS tag.
      touch /etc/NIXOS
      echo "Setting up system profile.."
      ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    '';
  # system.stateVersion = "23.05";
  fileSystems = {
    # TODO gpt-auto-generator already takes care of these two. not needed. But nixos insists. I think a udev rule is missing
    "/".device = "/dev/disk/by-partlabel/root-arm64";
    "/".fsType = "ext4";
  };
}
