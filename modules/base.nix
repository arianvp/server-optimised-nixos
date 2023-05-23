{
  boot.loader.systemd-boot.enable = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.repart.enable = true;
  nixpkgs.overlays = [
    (import ../overlays/systemd.nix)
    (import ../overlays/image-tools.nix)
  ];
}
