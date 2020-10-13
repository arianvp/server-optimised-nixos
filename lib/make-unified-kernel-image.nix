{ stdenv, systemd, utillinux }:

{ version, tries, os-release, cmdline, kernel, initrd }:
stdenv.mkDerivation {
  name = "${version}-linux+${toString tries}.efi";
  buildCommand = ''
    objcopy \
        --add-section .osrel="${os-release}"        --change-section-vma .osrel=0x20000    \
        --add-section .cmdline="${cmdline}"         --change-section-vma .cmdline=0x30000  \
        --add-section .linux="${kernel}/bzImage"    --change-section-vma .linux=0x2000000  \
        --add-section .initrd="${initrd}"           --change-section-vma .initrd=0x3000000 \
        "${systemd}/lib/systemd/boot/efi/linuxx64.efi.stub" $out
  '';
}
