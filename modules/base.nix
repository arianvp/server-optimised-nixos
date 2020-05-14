{ config, lib, pkgs, ... }: {
  imports = [
    ./kernel.nix
    ./stage-1.nix
    ./squashfs.nix
    # ../../nixpkgs/nixos/modules/misc/assertions.nix
  ];
  options = {
    system.build = lib.options.mkOption {
      internal = true;
      default = {};
      type = lib.types.attrsOf lib.types.package;
      description = ''
        Derivations used to set up the system;
      '';
    };
  };
  config = {
    system.build.runvm = (
      pkgs.writeScript "runner" ''
        #!${pkgs.stdenv.shell}
        exec ${pkgs.qemu_kvm}/bin/qemu-kvm -name nixos -m 512 \
          -drive index=0,id=drive1,file=${config.system.build.squashfs},readonly,media=cdrom,format=raw,if=virtio \
          -kernel ${config.system.build.kernel}/bzImage -initrd ${config.system.build.initrd} -nographic \
          -append "console=ttyS0 ${toString config.kernel.params} panic=-1" -no-reboot \
          -device virtio-rng-pci \
          -netdev user,id=user.0 -device e1000,netdev=user.0
      ''
    );
  };
}
