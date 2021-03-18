{ config, lib, pkgs, modulesPath, ... }:
{
  options.stage-2 = lib.mkOption {
    type = lib.types.submoduleWith {
      specialArgs.modulesPath  = pkgs.path + "/nixos/modules";
      modules = import (pkgs.path + "/nixos/modules/module-list.nix") ++ [{
        # TODO: top-level activation script depends on grub thing
        options.boot.loader.grub.configurationName = lib.mkOption {
          type = lib.types.str;
          default = "SONOS";
        };
      }];
    };
    default = {
      disabledModules = [
        "system/boot/stage-1.nix"
        "system/boot/loader/grub/grub.nix"
        "system/boot/loader/grub/memtest.nix"
        "system/boot/loader/grub/ipxe.nix"
        "system/boot/loader/systemd-boot/systemd-boot.nix"
        "system/boot/plymouth.nix"
        "system/boot/luksroot.nix"
        "system/boot/initrd-openvpn.nix"
        "system/boot/initrd-ssh.nix"
        "system/boot/initrd-network.nix"
        "system/boot/grow-partition.nix"
        # TODO: Required udev rules
        "tasks/swraid.nix"
        "tasks/bcache.nix"
        "tasks/filesystems/bcachefs.nix"
        "tasks/filesystems/btrfs.nix"
        "tasks/filesystems/cifs.nix"
        "tasks/filesystems/ecryptfs.nix"
        "tasks/filesystems/exfat.nix"
        "tasks/filesystems/ext.nix"
        "tasks/filesystems/f2fs.nix"
        "tasks/filesystems/glusterfs.nix"
        "tasks/filesystems/jfs.nix"
        "tasks/filesystems/nfs.nix"
        "tasks/filesystems/ntfs.nix"
        "tasks/filesystems/reiserfs.nix"
        "tasks/filesystems/unionfs-fuse.nix"
        "tasks/filesystems/vboxsf.nix"
        "tasks/filesystems/vfat.nix"
        "tasks/filesystems/xfs.nix"
        "tasks/filesystems/zfs.nix"
        "tasks/lvm.nix"
        "tasks/encrypted-devices.nix"

        # TODO Refactor to work with systemd-based initrd
        "config/console.nix"

        "config/gnu.nix"

        # TODO: implement initrd prepend
        "hardware/cpu/intel-microcode.nix"
        "hardware/cpu/amd-microcode.nix"

        # TODO: bootloader setting path is different
        "hardware/video/hidpi.nix"

        "virtualisation/virtualbox-guest.nix"

        "services/network-filesystems/nfsd.nix"
        "services/x11/display-managers/xpra.nix"
      ];
      nixpkgs.system = pkgs.targetPlatform.system;
      documentation.enable = false;

      # TODO: This is just there to trick the activation script to not contain
      # anything stage-1 related. need to fix
      boot.isContainer = true;
    };
  };

}
