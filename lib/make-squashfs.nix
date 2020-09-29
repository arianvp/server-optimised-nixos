{ stdenv, squashfsTools, closureInfo

, # The root directory of the squashfs filesystem is filled with the
  # closures of the Nix store paths listed here.
}:
{ storeContents }:

stdenv.mkDerivation {
  name = "squashfs.img";

  nativeBuildInputs = [ squashfsTools ];

  buildCommand =
    ''
      closureInfo=${closureInfo { rootPaths = storeContents; }}

      # Also include a manifest of the closures in a format suitable
      # for nix-store --load-db.
      cp $closureInfo/registration nix-path-registration

      mkdir -p rootfs/etc

      touch rootfs/etc/machine-id
      cat <<EOF > rootfs/etc/os-release
      NAME=Server Optimised NixOS
      EOF

      echo hello > rootfs/etc/hostname

      mkdir -p rootfs/boot

      find rootfs


      # Generate the squashfs image.
      mksquashfs rootfs/*  $out \
        -info -keep-as-directory -all-root -b 1048576 -comp xz -Xdict-size 100%
    '';
}
