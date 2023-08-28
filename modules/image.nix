{ config, pkgs, lib, modulesPath, ... }:
let
  cfg = config.image;

  loaderConf = pkgs.writeTextFile {
    name = "loader.conf";
    text = ''
      timeout ${toString config.boot.loader.timeout}
    '';
  };

  inherit (pkgs.stdenv.hostPlatform) linuxArch efiArch;
  EFIARCH = lib.toUpper efiArch;

  uki = pkgs.stdenv.mkDerivation {
    name = "${config.system.build.kernel.name}.efi";
    # usrhash=${pkgs.jq}/bin/jq -r '.[]|select(.type=="usr-${arch}") | .roothash' ${config.system.build.imageWithoutESP}/repart-output.json
    buildCommand = ''

    '';
  };

  closure = pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; };
  seed = "d03836b2-8e14-46e6-9524-d3e3d0b363dd";
in
{
  boot.initrd.availableKernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_net"
    "virtio_pci"
    "virtio_rng"
  ];

  boot.kernelParams = [
    "console=hvc0"
    "root=tmpfs"
    "systemd.journald.forward_to_console"
    "systemd.log_level=debug"
    # "mount.usr=PARTLABEL=usr"
  ];
  boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" "dm-verity" ];

  # We do this because we need the udev rules from the package
  boot.initrd.services.lvm.enable = true;

  boot.initrd.systemd = {
    additionalUpstreamUnits = [
      "veritysetup-pre.target"
      "veritysetup.target"
      "remote-veritysetup.target"
    ];
    storePaths = [
      "${config.boot.initrd.systemd.package}/lib/systemd/systemd-veritysetup"
      "${config.boot.initrd.systemd.package}/lib/systemd/system-generators/systemd-veritysetup-generator"
    ];
  };

  boot.initrd.supportedFilesystems = [ "erofs" ];

  system.build.image = pkgs.runCommand "image"
    {
      nativeBuildInputs = [
        pkgs.fakeroot
        pkgs.systemd-tools

        pkgs.dosfstools
        pkgs.mtools
        pkgs.erofs-utils

        pkgs.jq
      ];

    } ''
    mkdir -p $out
    mkdir -p repart.d

    cat <<EOA > repart.d/00-esp.conf
    [Partition]
    Type=esp
    Format=vfat
    SizeMinBytes=128M
    SizeMaxBytes=128M
    CopyFiles=${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi:/EFI/BOOT/BOOT${EFIARCH}.EFI
    CopyFiles=$out/Image.unsigned.efi:/EFI/Linux/Image.efi
    EOA

    cat <<EOB > repart.d/10-usr.conf
    [Partition]
    Type=usr
    Label=usr
    Format=erofs
    Minimize=yes
    Verity=data
    VerityMatchKey=usr
    CopyFiles=${closure}/registration:/store/.nix-path-registration
    EOB
    for path in $(cat ${closure}/store-paths); do
      echo "CopyFiles=$path:''${path#/nix}" >> repart.d/10-usr.conf
    done

    cat <<EOC > repart.d/20-usr-verity.conf
    [Partition]
    Type=usr-verity
    Verity=hash
    VerityMatchKey=usr
    SizeMinBytes=64M
    SizeMaxBytes=64M
    EOC

    fakeroot systemd-repart \
      --dry-run=no \
      --defer-partitions esp \
      --empty=create \
      --seed=${seed}  \
      --size=auto \
      --definitions=./repart.d \
      --json=pretty \
      $out/image.raw \
      | tee $out/repart-output.json

    usrhash=$(jq -r '.[]|select(.type=="usr-${linuxArch}") | .roothash' $out/repart-output.json)

    ${pkgs.systemd-tools}/lib/systemd/ukify \
      ${config.system.build.kernel}/Image \
      ${config.system.build.toplevel}/initrd  \
      --cmdline "${builtins.concatStringsSep " " config.boot.kernelParams} usrhash=$usrhash init=${config.system.build.toplevel}/init" \
      --os-release @${config.environment.etc."os-release".source} \
      --stub "${pkgs.systemd}/lib/systemd/boot/efi/linux${efiArch}.efi.stub"\
      --no-sign-kernel

    mv Image.unsigned.efi $out/Image.unsigned.efi


  
    fakeroot systemd-repart \
      --dry-run=no \
      --seed=${seed}  \
      --definitions=./repart.d \
      --json=pretty \
      $out/image.raw
  '';

}
