{ stdenv
, cpio
, closureInfo
, storeContents ? []
}:
stdenv.mkDerivation {
  name = "initrd";
  nativeBuildInputs = [ cpio ];
  buildCommand = ''
    closureInfo=${closureInfo { rootPaths = storeContents; }}
    mkdir root
    cp $closureInfo/registration root/nix-path-registration
    find $(cat $closureInfo/store-paths) -type f | cpio --make-directories --pass-through root
    find ${storeContents} -type f | cpio --make-directories --directory ${storeContents} --pass-through root

    mkdir $out
    cp -R root $out

    # (cat $closureInfo/store-paths) | cpio --directory / --create --format newc -R +0:+0 --reproducible  > $out
  '';
}
