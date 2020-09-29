{ lib, stdenv, dosfstools, mtools }:
{ size, files }:
stdenv.mkDerivation {
  name = "vfat";
  nativeBuildInputs = [ dosfstools mtools ];
  buildCommand = ''
    truncate --size ${toString size} $out
    mkfs.vfat -F32 $out
  '' + lib.concatStrings (lib.mapAttrsToList (target: source: "mcopy -i $out ${source} ::${target}") files);
}
