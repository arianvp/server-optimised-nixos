{ config, lib, pkgs, ... }:
let
  systemBuilder = ''
    mkdir $out
    ln -s ${config.system.build.kernel}/bzImage $out/kernel
    ln -s ${config.system.build.initrd}/initrd  $out/initrd
    echo -n "$kernelParams" >                   $out/kernel-params
  '';
  baseSystem = pkgs.stdenvNoCC.mkDerivation {
    name = "coreos";
    preferLocalBuild = true;
    allowSubstitutes = false;
    buildCommand = systemBuilder;
    kernelParams = config.kernel.params;
  };

  failedAssertions = map (x: x.message) (lib.filter (x: !x.assertion) config.assertions);

  showWarnings = res: lib.fold (w: x: builtins.trace "[1;31mwarning: ${w}[0m" x) res config.warnings;

  baseSystemAssertWarn = if failedAssertions != []
    then throw "\nFailed assertions:\n${lib.concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else showWarnings baseSystem;

  # Replace runtime dependencies
  system = baseSystemAssertWarn;
in
  {
    imports = [
      ./kernel.nix
      ./stage-1.nix
      ../../nixpkgs/nixos/modules/misc/assertions.nix
    ];
    options = {
      system.build = lib.options.mkOption {
        internal = true;
        default = {};
        type = lib.types.attrsOf lib.types.package;
        description = ''
          Derivations used to set up the system;
        '';
      };
    };
    config = {
      system.build.system = system;
    };
  }
