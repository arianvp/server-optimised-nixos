{ swift, stdenv, Dispatch, Foundation }:
stdenv.mkDerivation {
  pname = "runvf";
  version = "0.0.0";
  src = ./.;
  nativeBuildInputs = [ swift ];
  buildInputs = [ Dispatch Foundation ];
}
