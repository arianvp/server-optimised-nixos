{ swift, swiftpm, stdenv, Dispatch, Foundation, Virtualization }:
stdenv.mkDerivation {
  pname = "runvf";
  version = "0.0.0";
  src = ./.;
  nativeBuildInputs = [ swift swiftpm ];
  buildInputs = [
    Dispatch
    Foundation
    Virtualization
  ];
}
