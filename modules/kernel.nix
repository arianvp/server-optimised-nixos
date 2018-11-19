{ config, lib, pkgs, ...}:
{
  options = {
    kernel.params = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Parameters that will be passed to the kernel
      '';
    };
  };
  config = {
    system.build.kernel = pkgs.linuxPackages.kernel;
  };
}

