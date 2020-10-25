{
  description = "A very basic flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
  flake-utils.eachDefaultSystem (system: let pkgs = import nixpkgs { inherit system; }; in {
  });
}
