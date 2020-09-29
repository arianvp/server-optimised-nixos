{ pkgs, hostPkgs, config, ... }:
let
  squashfs = pkgs.makeSquashfs {
    storeContents = pkgs.systemd;
  };
in
{
  config.system.build.stub = pkgs.makeUnifiedKernelImage {
    version = "0.0.1";
    os-release = pkgs.writeText "os-release" ''
      NAME=Server Optimised NixOS
      PRETTY_NAME=Server Optimised NixOS (0.0.1)
      ID=nixos
      VERSION_ID=0.0.1
    '';
    cmdline = pkgs.runCommand "cmdline" {} ''
      echo -n "roothash=$(cat ${config.system.build.image.verity}/hash) ${toString config.kernel.params}" > $out
    '';
    initrd = config.system.build.initrd;
    kernel = config.system.build.kernel;
  };
  config.system.build.image = pkgs.makeEFI {
    esp = pkgs.makeVFAT {
      size = 1024 * 1024 * 1024;
      files = {
        # TODO This is a bit naughty; and should move into make-esp.nix once make-vat.nix is renamed to it. Then we do not need this hashmap unsafe hack
        "EFI/Linux/${builtins.baseNameOf (builtins.unsafeDiscardStringContext config.system.build.stub)}" = config.system.build.stub;
        "EFI/BOOT/BOOTX64.EFI" = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-bootx64.efi";
        "EFI/systemd/systemd-bootx64.efi" = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-bootx64.efi";
        "loader/loader.conf" = pkgs.writeText "loader.conf" ''
          timeout 10
          # editor no
        '';
      };
    };
    root = squashfs;
  };
  config.system.build.testScript = pkgs.writeScript "test"
    ''
      ${pkgs.kmod}/bin/modprobe loop
      mkdir mounted
      SYSTEMD_LOG_LEVEL=debug ${pkgs.systemd}/lib/systemd/systemd-dissect ${config.system.build.image} --root-hash $(cat ${config.system.build.image.verity}/hash) --mount mounted -r
    '';
  # Make sure that the generated image is recognised by systemd as bootable
  config.system.build.test = hostPkgs.vmTools.runInLinuxVM (
    pkgs.runCommand "test" {
      test = config.system.build.testScript;
    }
      ''
        $test
      ''
  );
}
