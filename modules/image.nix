{ pkgs, hostPkgs, config, ... }:
let
  squashfs = pkgs.makeSquashfs {
    storeContents = pkgs.systemd;
  };
in
{
  config.system.build.image = pkgs.makeEFI {
    esp = pkgs.makeVFAT {
      size = 1024 * 1024 * 1024;
      files = {};
    };
    root = squashfs;
  };
  config.system.build.testScript = pkgs.writeScript "test"
  ''
    ${pkgs.kmod}/bin/modprobe loop
    SYSTEMD_LOG_LEVEL=debug ${pkgs.systemd}/lib/systemd/systemd-dissect ${config.system.build.image} --root-hash $(cat ${config.system.build.image.verity}/hash)
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
