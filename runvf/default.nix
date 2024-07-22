{ swift, swiftpm, stdenv, swiftpm2nix, darwin, Dispatch, Foundation, apple_sdk_12_3 }:
let
  generated = swiftpm2nix.helpers ./nix;
in
stdenv.mkDerivation {
  pname = "runvf";
  version = "0.0.0";
  src = ./.;
  nativeBuildInputs = [ darwin.sigtool swift swiftpm ];
  buildInputs = [
    Dispatch
    Foundation
    apple_sdk_12_3.frameworks.Virtualization
  ];
  # The helper provides a configure snippet that will prepare all dependencies
  # in the correct place, where SwiftPM expects them.
  configurePhase = generated.configure;

  # NOTE: This works but idk why
  postFixup = ''
    	codesign -s - -f --entitlements runvf.entitlements $out/bin/runvf
  '';

}
