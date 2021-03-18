final: prev: {
  makeSquashfs = final.callPackage ../lib/make-squashfs.nix {};
  makeInitrd = final.callPackage ../lib/make-initrd.nix {};
  makeVerity = final.callPackage ../lib/make-verity.nix {};
  makeEFI = final.callPackage ../lib/make-efi.nix {};
  makeVFAT = final.callPackage ../lib/make-vfat.nix {};
  makeUnifiedKernelImage = final.callPackage ../lib/make-unified-kernel-image.nix {};
}
