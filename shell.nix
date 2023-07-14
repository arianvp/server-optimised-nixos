let
  flake = builtins.getFlake (toString ./.);
in
flake.outputs.packages.${builtins.currentSystem}.image

