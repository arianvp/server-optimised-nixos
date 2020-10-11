{ pkgs, hostPkgs, config, ... }:
let
  version = "0.0.1";
  os-release = pkgs.writeText "os-release" ''
    NAME=Server Optimised NixOS
    PRETTY_NAME=Server Optimised NixOS (0.0.1)
    ID=nixos
    VERSION_ID=0.0.1
  '';
  emptydir = pkgs.runCommand "emptydir" {} "mkdir -p $out";
  emptyfile = pkgs.runCommand "emptyfile" {} "touch $out";

  rootfs = pkgs.linkFarm "rootfs" [
    # { name = "etc/os-release"; path = "${os-release}"; }

    # An empty machine-id will cause systemd to temporarily bind-mount a read-only machine-id
    # The real question is though; will this work with symlinks? lets find out
    # { name = "etc/machine-id"; path = "${emptyfile}"; }

    # TODO: These needed to be there? systemd-nspawn insists on mounting them; which it has no business in doing. patch
    # { name = "etc/localtime"; path = "${emptyfile}"; }
    # { name = "etc/resolv.conf"; path = "${emptyfile}"; }

    # TODO: mimick, or abstract away stage-1 into stage-2? this is very similar!
    # { name = "sbin/init"; path = "${pkgs.systemd}/lib/systemd/systemd"; }

    { name = "sbin/init"; path = "${config.stage-2.system.build.toplevel}/init"; }

    # TODO I don't remember why this was needed. but we need it? lets fix it?
    # { name = "sbin/modprobe"; path = "${pkgs.kmod}/bin/modprobe"; }
  ];

  squashfs = pkgs.makeSquashfs {
    inherit os-release;
    storeContents = rootfs;
  };
in
  {
  config.system.build.squashfs = squashfs;
  config.system.build.stub = pkgs.makeUnifiedKernelImage {
    inherit version os-release;
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
  config.system.build.dissect = pkgs.writeScript "test"
    ''
      ${pkgs.kmod}/bin/modprobe loop
      mkdir mounted
      ${pkgs.systemd}/lib/systemd/systemd-dissect ${config.system.build.image} --root-hash $(cat ${config.system.build.image.verity}/hash) --mount mounted --read-only
    '';
  config.system.build.nspawn = pkgs.writeScript "test"
    ''
      ${pkgs.systemd}/bin/systemd-nspawn --volatile=overlay --image ${config.system.build.image} --root-hash $(cat ${config.system.build.image.verity}/hash) --read-only --boot --register=false
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
