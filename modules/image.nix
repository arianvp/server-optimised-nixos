{ config, pkgs, lib, ... }:
let
  uki = pkgs.makeUnifiedKernelImage {
    inherit (config.system.build.kernel) version;
    tries = 3;
    os-release = config.environment.etc."os-release".source;
    kernel = "${config.system.build.kernel}/Image";
    initrd = "${config.system.build.initialRamdisk}/initrd";
    cmdline = pkgs.writeTextFile {
      name = "cmdline";
      text = lib.concatStringsSep " " ([ "init=${config.system.build.toplevel}/init" ] ++ config.boot.kernelParams);
    };
  };

  # See https://uapi-group.org/specifications/specs/boot_loader_specification/
  esp = pkgs.runCommand "00-esp.conf" { } ''
    cat <<EOF > $out
    [Partition]
    Type=esp
    Format=vfat
    SizeMinBytes=256M
    SizeMaxBytes=256M
    CopyFiles=${config.systemd.package}/lib/systemd/boot/efi/systemd-bootaa64.efi:/EFI/BOOT/BOOTAA64.EFI
    CopyFiles=${config.systemd.package}/lib/systemd/boot/efi/systemd-bootaa64.efi:/EFI/systemd/systemd-bootaa64.efi
    CopyFiles=${uki}:/EFI/Linux/${baseNameOf uki}
    EOF
  '';

  closure = pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; };
  rootPartition = pkgs.runCommand "00-root.conf" { } ''
    cat <<EOF > $out
    [Partition]
    Type=root
    Format=ext4
    SizeMinBytes=1G
    MakeDirectories=/boot
    CopyFiles=${closure}/registration
    EOF
    for path in $(cat ${closure}/store-paths); do
      echo "CopyFiles=$path" >> $out
    done
  '';
  # TODO: nix-store --load-db < /registration

  partitions = [ esp rootPartition ];

  definitionsDirectory = pkgs.runCommand "systemd-repart-definitions" { } ''
      mkdir -p $out
      ${(lib.concatStringsSep "\n"
    (map (pkg: "cp ${pkg} $out/${pkg.name}") partitions)
    )}
  '';
in
{
  config.system.build = {
    partitions = definitionsDirectory;
    uki = uki;
    image = pkgs.runCommand "image"
      {
        nativeBuildInputs = [
          pkgs.systemd-repart
          pkgs.dosfstools # vfat
          pkgs.mtools # vfat
          pkgs.e2fsprogs # ext4
          pkgs.fakeroot
        ];
        inherit definitionsDirectory;
        seed = "d03836b2-8e14-46e6-9524-d3e9d0b363dd";
      }
      ''
        fakeroot systemd-repart --seed $seed --size auto --definitions $definitionsDirectory --empty=create $out
      '';

  };
}
