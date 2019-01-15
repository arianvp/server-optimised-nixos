{ stdenv, cpio, closureInfo, storeContents ? []
}:
stdenv.mkDerivation {
  name = "initrd";
  nativeBuildInputs = [ cpio ];
  buildCommand = 
    ''
    closureInfo=${closureInfo { rootPaths = storeContents; }}
    cp $closureInfo/registration nix-path-registration

    '';
}
