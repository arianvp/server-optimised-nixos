{ pkgs, lib, config, ... }:
# Very simple implementation of environment.etc Allows you to populate the
# /etc directory with symlinks to the nix store.
# All the paths that are not in here are mutable by default
with lib;
{
  options = {
    environment.etc = mkOption {
      description = ''
        Files that should exist in /etc.
        Any missing directories are created on the fly. Note that those
        directories will be mutable.

        We might in the future support 'opt-in' mutability

      '';
      type = types.loaOf (
        types.submodule (
          { name, config, ... }: {
            options = {
              target = mkOption {
                type = types.str;
              };
              source = mkOption {
                type = types.path;
              };
              text = mkOption {
                type = types.str;
              };
            };
            config = {
              target = mkDefault name;
              source =
                mkIf (config.text != null)
                  (mkDefault (pkgs.writeText (baseNameOf name) config.text));
            };
          }
        )
      );
    };
  };

  # TODO
  config = {
  };
}
