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

    path=$(realpath root)

    cp $closureInfo/registration root/nix-path-registration
    find $(cat $closureInfo/store-paths) | cpio --make-directories --pass-through $path
    (cd ${storeContents} && (find . | cpio --make-directories --pass-through $path))

    (cd $path && (find . | cpio -o -H newc | gzip > $out))

  '';
}
