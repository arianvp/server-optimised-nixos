final: prev: {
  makeInitrd = final.callPackage ../lib/make-initrd.nix { };
  makeUnifiedKernelImage = final.callPackage ../lib/make-unified-kernel-image.nix { };
}
