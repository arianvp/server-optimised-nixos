self: super: {
  systemd = self.callPackage (
    { stdenv
    , acl
    , coreutils
    , fetchFromGitHub
    , getent
    , gperf
    , kmod
    , libcap
    , libuuid
    , linuxHeaders
    , m4
    , meson
    , ninja
    , pam
    , pkgconfig
    , patchelf
    , buildPackages # TODO remove?
    }: stdenv.mkDerivation {
      version = "245.3";
      pname = "systemd";
      src = /home/arian/Projects/systemd;
      # src = fetchFromGitHub {
      #   owner = "systemd";
      #   repo = "systemd-stable";
      #   rev = "0f5047b7d393cfba37f91e25cae559a0bc910582";
      #   sha256 = "0wyh14gbvvpgdmk1mjgpxr9i4pv1i9n7pnwpa0gvjh6hq948fyn2";
      # };
      nativeBuildInputs = [
        coreutils
        getent
        gperf
        m4
        meson
        ninja
        pkgconfig
        patchelf
        # TODO needed for xml-helper.py but why is python a build dependency in the first place? Unwieldy for bootstrap

        (buildPackages.python3Packages.python.withPackages ( ps: with ps; [ lxml ]))

      ];
      buildInputs = [
        acl
        kmod
        libcap
        libuuid
        linuxHeaders
        pam
      ];
      doCheck = false;
      enableParallelBuilding = true;

      preConfigure = ''
        for dir in tools src/resolve test src/test; do
          patchShebangs $dir
        done
      '';

      # NOTE: If we set DESTDIR to $out it installs everything to $out/$out but the
      # library paths etc are correct!  We want to configure systemd to read
      # from /etc but write to $out/etc This is the hack that seems to make
      # that work as everything ends upt in $out/$out and etc ends up in
      # $out/etc and we fix it up at the end
      preInstall = ''
        export DESTDIR="$out"
      '';

      mesonFlags = [
        "-Dsplit-usr=false" # This just seems to make things more complicated
        "-Drootprefix=${placeholder "out"}"
        "-Dsysconfdir=/etc" # NOTE: This is on purpose!!
        "-Dtests=false"
        "-Dinstall-tests=false"
        "-Dsysvinit-path="
        "-Dsysrcnd-path="
      ];

      # NOTE: We move $out/$out back to $out do undo the damage that DESTDIR did
      # Note that $out/etc exists already at this point
      postInstall = ''
        rm -rf $out/var
        mv $out/$out/* $out
        rm -rf $out/nix
      '';
    }
  ) {};
}
