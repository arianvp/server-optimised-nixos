{ lib, stdenv, dosfstools, mtools }:
{ size, files }:
stdenv.mkDerivation {
  name = "vfat";
  nativeBuildInputs = [ dosfstools mtools ];
  buildCommand = ''
    truncate --size ${toString size} $out
    mkfs.vfat -F32 $out
    mmd -i $out ::EFI
    mmd -i $out ::EFI/Linux
    mmd -i $out ::EFI/systemd
    mmd -i $out ::EFI/BOOT
    mmd -i $out ::loader

  '' + lib.concatStrings (lib.mapAttrsToList (target: source: "mcopy -i $out ${source} ::${target}\n") files);
}
