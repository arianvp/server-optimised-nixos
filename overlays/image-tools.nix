self: super: {
  makeSquashfs = self.callPackage ../lib/make-squashfs.nix {};
  makeInitrd = self.callPackage ../lib/make-initrd.nix {};
  makeVerity = self.callPackage ../lib/make-verity.nix {};
  makeEFI = self.callPackage ../lib/make-efi.nix {};
  makeVFAT = self.callPackage ../lib/make-vfat.nix {};
  makeUnifiedKernelImage = self.callPackage ../lib/make-unified-kernel-image.nix {};

  example = self.callPackage ../example.nix {};

  lol = self.makeVFAT {
    size = 1024*1024*1024;
    files = { "EFI\\Linux" = ../README.md; };
  };
}
