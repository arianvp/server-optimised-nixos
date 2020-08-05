self: super: {
  makeSquashfs = self.callPackage ../lib/make-squashfs.nix {};
  makeInitrd = self.callPackage ../lib/make-initrd.nix {};
  makeVerity = self.callPackage ../lib/make-verity.nix {};
  makeEFI = self.callPackage ../lib/make-efi.nix {};

}
