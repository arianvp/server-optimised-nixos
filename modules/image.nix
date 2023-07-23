{ config, pkgs, lib, ... }:
let

  loaderConf = pkgs.writeTextFile {
    name = "loader.conf";
    text = ''
      timeout 0
    '';
  };

  esp = pkgs.writeTextFile {
    name = "00-esp.conf";
    text = ''
      [Partition]
      Type=esp
      Format=vfat
      SizeMinBytes=1G
      SizeMaxBytes=1G
      CopyFiles=${config.systemd.package}/lib/systemd/boot/efi/systemd-bootaa64.efi:/EFI/BOOT/BOOTAA64.EFI
      CopyFiles=${config.systemd.package}/lib/systemd/boot/efi/systemd-bootaa64.efi:/EFI/systemd/systemd-bootaa64.efi
      CopyFiles=${config.system.build.uki}:/EFI/Linux/${baseNameOf config.system.build.uki}
      CopyFiles=${loaderConf}:/loader/loader.conf
    '';
  };

  closure = pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; };

  rootPartition = pkgs.runCommand "00-root.conf" { } ''
    cat <<EOF > $out
    [Partition]
    Type=root
    Format=ext4
    Minimize=guess

    MakeDirectories=/efi /etc /home /nix/store /opt /root /run /srv /tmp /var /sys /proc /usr /bin /dev
    CopyFiles=${closure}/registration:/nix/store/nix-path-registration
    EOF
    for path in $(cat ${closure}/store-paths); do
      echo "CopyFiles=$path" >> $out
    done
  '';

  partitions = [ esp rootPartition ];

  definitions = pkgs.runCommand "repart.d" { } ''
    mkdir -p $out
    ${(lib.concatStringsSep "\n" (map (f: "cp ${f} $out/${f.name}") partitions))}
  '';
in
{
  config.system.build = {
    inherit closure definitions;
    systemd-tools = pkgs.systemd-tools;
    uki = pkgs.stdenv.mkDerivation {
      name = "${config.system.build.kernel.version}-linux.efi";
      nativeBuildInputs = [ pkgs.jq ];
      # TODO: This shouldn't depend on config.environment.etc."os-release".source
      buildCommand = ''
        boot_json=${config.system.build.toplevel}/boot.json
        kernel=$(jq -r '."org.nixos.bootspec.v1".kernel' "$boot_json")
        kernelParams=$(jq -j '."org.nixos.bootspec.v1".kernelParams | join(" ")' "$boot_json")
        initrd=$(jq -r '."org.nixos.bootspec.v1".initrd' "$boot_json")
        init=$(jq -r '."org.nixos.bootspec.v1".init' "$boot_json")


        ${pkgs.systemd-tools}/lib/systemd/ukify \
          $kernel \
          $initrd \
          --cmdline "$kernelParams init=$init" \
          --os-release @${config.environment.etc."os-release".source} \
          --stub "${pkgs.systemd}/lib/systemd/boot/efi/linux${pkgs.stdenv.targetPlatform.efiArch}.efi.stub"\
          --no-sign-kernel
        cp Image.unsigned.efi $out
      '';
    };
    nspawn = pkgs.writeScriptBin "nspawn" ''
      systemd-nspawn --volatile=overlay --image ${config.system.build.image} ${config.system.build.toplevel}/init
    '';
    image = pkgs.runCommand "image"
      {
        nativeBuildInputs = [
          pkgs.systemd-tools
          pkgs.dosfstools # vfat
          pkgs.mtools # vfat
          pkgs.e2fsprogs # ext4
          pkgs.fakeroot
          pkgs.squashfsTools
        ];
        inherit definitions;
        seed = "d03836b2-8e14-46e6-9524-d3e3d0b363dd";
      }
      ''
        fakeroot systemd-repart --seed $seed --size auto --definitions $definitions --empty=create $out
      '';

  };
}
