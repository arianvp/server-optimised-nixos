{ config, lib, pkgs, ... }:
let
  systemBuilder = ''
    mkdir $out
    ln -s ${config.system.build.kernel}/bzImage $out/kernel
    ln -s ${config.system.build.initrd}/initrd  $out/initrd
    echo -n "$kernelParams" >                   $out/kernel-params
  '';
  baseSystem = pkgs.stdenvNoCC.mkDerivation {
    name = "baseSystem";
    preferLocalBuild = true;
    allowSubstitutes = false;
    buildCommand = systemBuilder;
    kernelParams = config.kernel.params;
  };

  failedAssertions = map (x: x.message) (lib.filter (x: !x.assertion) config.assertions);

  showWarnings = res: lib.fold (w: x: builtins.trace "[1;31mwarning: ${w}[0m" x) res config.warnings;

  baseSystemAssertWarn = if failedAssertions != []
    then throw "\nFailed assertions:\n${lib.concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else showWarnings baseSystem;

  # Replace runtime dependencies
  system = baseSystemAssertWarn;
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
      system.build.system = system;
      system.build.runvm = pkgs.writeScript "runner" ''
        #!${pkgs.stdenv.shell}
        exec ${pkgs.qemu_kvm}/bin/qemu-kvm -name nixos -m 512 \
          -drive index=0,id=drive1,file=${config.system.build.squashfs},readonly,media=cdrom,format=raw,if=virtio \
          -kernel ${config.system.build.kernel}/bzImage -initrd ${config.system.build.initrd}/initrd -nographic \
          -append "console=ttyS0 ${toString config.kernel.params} quiet panic=-1" -no-reboot \
          -device virtio-rng-pci
      '';
    };
  }
