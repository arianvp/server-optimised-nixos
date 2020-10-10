{ stdenv, squashfsTools, closureInfo }:

# The root directory of the squashfs filesystem is filled with the
# closures of the Nix store paths listed here.
{ os-release, storeContents }:

stdenv.mkDerivation {
  name = "squashfs.img";

  nativeBuildInputs = [ squashfsTools ];

  buildCommand =
    ''
      closureInfo=${closureInfo { rootPaths = storeContents; }}

      mkdir -p rootfs/{tmp,run,sys,proc,dev,etc,boot}
      touch rootfs/etc/machine-id
      cp ${os-release} rootfs/etc/os-release

      mkdir -p rootfs/nix/store

      # Also include a manifest of the closures in a format suitable
      # for nix-store --load-db.
      cp $closureInfo/registration rootfs/nix/store/nix-path-registration

      # TODO: It's not great that we copy these files inbetween. But i do not
      # know how to avoid it.
      cp -a $(cat $closureInfo/store-paths) rootfs/nix/store


      # Generate the squashfs image.
      mksquashfs rootfs/*  ${storeContents}/*  $out \
        -info -keep-as-directory -all-root -b 1048576 -comp xz -Xdict-size 100%
    '';
}
