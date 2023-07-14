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
  # TODO: nix-store --load-db < /registration

  partitions = [ esp rootPartition ];

  definitions = pkgs.runCommand "repart.d" { } ''
    mkdir -p $out
    ${(lib.concatStringsSep "\n" (map (f: "cp ${f} $out/${f.name}") partitions))}
  '';
in
{
  /*config.boot.kernelPatches = [{
    name = "efi-zboot";
    patch = null;
    extraConfig = ''
      EFI_ZBOOT y
    '';
  }];*/
  # TODO: Fix this once we got a working kernel
  # TODO: Why does this not work if falsE? Why do we not get a login shell?
  config.boot.isContainer = false;
  config.services.nginx.enable = true;
  config.services.getty.autologinUser = "root";
  # config.boot.modprobeConfig.enable = false; #makes activation fail
  # config.environment.etc."modprobe.d/nixos.conf".text = ""; # HACK
  config.system.build = {
    inherit closure definitions;
    systemd-tools = pkgs.systemd-tools;
    uki = pkgs.stdenv.mkDerivation {
      name = "${config.system.build.kernel.version}-linux.efi";
      buildCommand = ''
        ${pkgs.systemd-tools}/lib/systemd/ukify \
          ${config.system.build.kernel}/Image \
          ${config.system.build.initialRamdisk}/initrd \
          --cmdline "${lib.concatStringsSep " " config.boot.kernelParams} init=${config.system.build.toplevel}/init" \
          --os-release @${config.environment.etc."os-release".source} \
          --uname ${config.system.build.kernel.version} \
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
