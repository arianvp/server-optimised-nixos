{ stdenv, systemd, utillinux }:

{ version, tries, os-release, cmdline, kernel, initrd }:
stdenv.mkDerivation {
  # ENTRY-TOKEN-KERNEL-VERSION[+TRIES].efi
  # In our case nix store hash is the ENTRY-TOKEN
  name = "${version}-linux+${toString tries}.efi";
  # TODO: linuxaa64 based on stdenv
  buildCommand = ''
    objcopy \
        --add-section .osrel="${os-release}"        --change-section-vma .osrel=0x20000    \
        --add-section .cmdline="${cmdline}"         --change-section-vma .cmdline=0x30000  \
        --add-section .linux="${kernel}"            --change-section-vma .linux=0x2000000  \
        --add-section .initrd="${initrd}"           --change-section-vma .initrd=0x3000000 \
        "${systemd}/lib/systemd/boot/efi/linuxaa64.efi.stub" $out
  '';
}
