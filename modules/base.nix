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

  networking.useNetworkd = true;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;


  documentation.nixos.enable = false;
  system.disableInstallerTools = true;

  nix.enable = true;
  nix.channel.enable = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  systemd.additionalUpstreamSystemUnits = [
  ];

  users.users.arian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "arian";
  };

  systemd.services.debug-things = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "journal+console";
    };
    script = ''
      ls /etc/pam.d
      cat /etc/passwd
      cat /etc/shadow
    '';


  };

  # systemd.services.console-getty.enable = true;
  # services.getty.autologinUser = "arian";

  fileSystems."/" = {
    fsType = "tmpfs";
    device = "tmpfs";
  };

  boot.initrd.availableKernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_net"
    "virtio_pci"
    "virtio_rng"
    "virtio_blk"
    "virtio_scsi"
    "virtiofs"
  ];

  boot.kernelParams = [
    "console=hvc0"
    "rescue"
    "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
    # "systemd.journald.forward_to_console"
    "systemd.log_level=debug"
    # "mount.usr=PARTLABEL=usr"
  ];

  # TODO(arianvp): Why are we loading these explicitly again?
  boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" "dm-verity" ];

  system.stateVersion = "24.05";
}

