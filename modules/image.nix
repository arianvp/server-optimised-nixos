{ config, pkgs, lib, ... }:
let
  listOfDefinitions = [ esp rootPartition ];

  definitionsDirectory = pkgs.runCommand "systemd-repart-definitions" { } ''
      mkdir -p $out
      ${(lib.concatStringsSep "\n"
    (map (pkg: "cp ${pkg} $out/${pkg.name}") listOfDefinitions)
    )}
  '';

  closure = pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; };

  uki = pkgs.makeUnifiedKernelImage
    {
      inherit (config.system.build.kernel) version;
      tries = 3;
      os-release = config.environment.etc."os-release".source;
      inherit (config.system.build) kernel;
      initrd = config.system.build.initialRamdisk;
      cmdline = pkgs.writeTextFile {
        name = "cmdline";
        text = "root=PARTLABEL=root init=/init";
      };
    };

  
  copyFiles = lib.concatStringsSep " " [
    "${config.systemd.package}/lib/systemd/boot/efi/systemd-bootaa64.efi:/EFI/BOOT/BOOTAA64.EFI"
  ];

  esp = pkgs.runCommand "00-esp.conf" { } ''
    cat <<EOF > $out
    [Partition]
    Type=esp
    Format=vfat
    CopyFiles=
    EOF
  '';

  rootPartition = pkgs.runCommand "00-root.conf" { } ''
    cat <<EOF > $out
    [Partition]
    Type=root
    Format=ext4
    MakeDirectories=/boot
    CopyFiles=${closure}/registration $(cat ${closure}/store-paths)
    EOF
  '';
  # TODO: nix-store --load-db < /registration
in
{
  options = { };
  config.system.build.partitions = definitionsDirectory;
  config.system.build.uki = uki;
  config.system.build.image = pkgs.runCommand "image"
    {
      nativeBuildInputs = [
        pkgs.systemd
        pkgs.dosfstools # vfat
        pkgs.mtools # vfat
        pkgs.e2fsprogs # ext4
      ];
    }
    # TODO: specify size
    ''
      systemd-repart --size 3G --definitions ${definitionsDirectory} --empty=create $out
    '';
}
