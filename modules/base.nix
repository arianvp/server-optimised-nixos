{ config, lib, hostPkgs, pkgs, ... }:
let
  ovmf = pkgs.OVMF-secureBoot.fd;
  efiPrefix =
    if (pkgs.stdenv.isi686 || pkgs.stdenv.isx86_64) then "${ovmf}/FV/OVMF"
    else if pkgs.stdenv.isAarch64 then "${ovmf}/FV/AAVMF"
    else throw "No EFI firmware available for platform";
  efiFirmware = "${efiPrefix}_CODE.fd";
  efiVarsDefault = "${efiPrefix}_VARS.fd";
in
{
  imports = [
    ./kernel.nix
    ./stage-1.nix
    ./stage-2.nix
    ./image.nix
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


    kernel.params = [
      "console=ttyS0"
      "panic=-1"
      "systemd.log_level=debug"
      "rd.systemd.log_level=debug"
      "udev.log-priority=debug"
      "rd.udev.log-priority=debug"
      "systemd.volatile=overlay"
    ];

    system.build.runvm =
      let
        options = [
          "-drive index=0,id=drive1,file=${config.system.build.image},readonly,media=cdrom,format=raw,if=virtio"
          "-nographic"
          "-device virtio-rng-pci"
          "-netdev user,id=user.0"
          "-device e1000,netdev=user.0"
          "-drive if=pflash,format=raw,unit=0,readonly,file=${efiFirmware}"
          "-drive if=pflash,format=raw,unit=1,file=$efiVars"
        ];
      in
        pkgs.writeScript "runner" ''
          #!${hostPkgs.stdenv.shell}
          efiVars=./efi-vars.fd
          cp ${efiVarsDefault} $efiVars
          chmod +w $efiVars
          exec ${hostPkgs.qemu_kvm}/bin/qemu-kvm -name nixos -m 512 ${toString options}
        '';
  };
}
