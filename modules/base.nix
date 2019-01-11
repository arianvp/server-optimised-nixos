{ config, lib, pkgs, ... }:
let

  failedAssertions = map (x: x.message) (lib.filter (x: !x.assertion) config.assertions);

  # showWarnings : a -> a
  showWarnings = res: lib.fold (w: x: builtins.trace "[1;31mwarning: ${w}[0m" x) res config.warnings;

  #  showWarningsOrFail : a -> a
  showWarningsOrFail = res:
    if failedAssertions != []
      then throw "\nFailed assertions:\n${lib.concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
      else showWarnings res;
in
  {
    imports = [
      ./kernel.nix
      ./stage-1.nix
      ./squashfs.nix
      ../../nixpkgs/nixos/modules/misc/assertions.nix
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
      system.build.runvm = showWarningsOrFail (pkgs.writeScript "runner" ''
        #!${pkgs.stdenv.shell}
        exec ${pkgs.qemu_kvm}/bin/qemu-kvm -name nixos -m 512 \
          -drive index=0,id=drive1,file=${config.system.build.squashfs},readonly,media=cdrom,format=raw,if=virtio \
          -kernel ${config.system.build.kernel}/bzImage -initrd ${config.system.build.initrd}/initrd -nographic \
          -append "console=ttyS0 ${toString config.kernel.params} quiet panic=-1" -no-reboot \
          -device virtio-rng-pci
      '');
    };
  }
