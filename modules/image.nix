{ config, pkgs, lib, ... }: {
  options = { };
  config.system.build.image = pkgs.runCommand "image"
    {
      nativeBuildInputs = [
        pkgs.systemd
        pkgs.dosfstools
        pkgs.mtools
        pkgs.e2fsprogs
      ];
    }
    # TODO: specify size
    ''
      systemd-repart \
        --empty=create \
        --size=2G \
        --definitions ${config.system.build.partitionDefinitions} \
        $out
    '';
}
