{ config, pkgs, lib, modulesPath, ... }:
let
  cfg = config.image;

  loaderConf = pkgs.writeTextFile {
    name = "loader.conf";
    text = ''
      timeout ${toString config.boot.loader.timeout}
    '';
  };

  arch = pkgs.stdenv.hostPlatform.efiArch;
  ARCH = lib.toUpper arch;

  uki = pkgs.stdenv.mkDerivation {
    name = "${config.system.build.kernel.name}.efi";
    buildCommand = ''
      ${pkgs.systemd-tools}/lib/systemd/ukify \
        ${config.system.build.kernel}/Image \
        ${config.system.build.toplevel}/initrd  \
        --cmdline "${builtins.concatStringsSep " " config.boot.kernelParams} init=${config.system.build.toplevel}/init" \
        --os-release @${config.environment.etc."os-release".source} \
        --stub "${pkgs.systemd}/lib/systemd/boot/efi/linux${arch}.efi.stub"\
        --no-sign-kernel
      cp Image.unsigned.efi $out
    '';
  };

  closure = pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; };
  systemd-boot = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${arch}.efi";
in
{
  imports = [ "${modulesPath}/image/repart.nix" ];

  boot.initrd.availableKernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_net"
    "virtio_pci"
    "virtio_rng"
  ];

  boot.kernelParams = [ "console=hvc0" ];
  boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];

  image.repart = {
    name = "nixos";
    partitions = {
      esp = {
        contents = {
          "/EFI/BOOT/BOOT${ARCH}.EFI".source = systemd-boot;
          "/EFI/systemd/systemd-boot${arch}.efi".source = systemd-boot;
          "/EFI/Linux/${lib.strings.sanitizeDerivationName (baseNameOf "${uki}")}".source = uki;
          "/EFI/loader/loader.conf".source = loaderConf;
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = "256M";
        };
      };
      root = {
        storePaths = [ config.system.build.toplevel ];
        contents."/nix/store/nix-path-registration".source = "${closure}/registration";
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Minimize = "guess";
          MakeDirectories = "/efi /etc /home /nix/store /opt /root /run /srv /tmp /var /sys /proc /usr /bin /dev";
        };
      };
    };
  };
}
