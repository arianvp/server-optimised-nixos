self: super: {
  # These tests are slow; disable them for now for interactive dev
  # bash-completion = super.bash-completion.overrideAttrs (old: old // { doCheck = false; } );

  # use old systemd

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
    , cryptsetup
    , m4
    , meson
    , ninja
    , pam
    , pkgconfig
    , patchelf
    , python3 # TODO remove? This was buildPackages.python3 before by the way
    }: stdenv.mkDerivation {
      version = "245.3";
      pname = "systemd";
      # src = /home/arian/Projects/systemd;
      src = fetchFromGitHub {
        owner = "systemd";
        repo = "systemd-stable";
        rev = "0f5047b7d393cfba37f91e25cae559a0bc910582";
        sha256 = "0wyh14gbvvpgdmk1mjgpxr9i4pv1i9n7pnwpa0gvjh6hq948fyn2";
      };
      nativeBuildInputs = [
        coreutils
        getent
        gperf
        m4
        meson
        ninja
        pkgconfig
        cryptsetup
        patchelf
        (python3.withPackages (p: [ p.lxml ]))

      ];
      buildInputs = [
        acl
        kmod
        libcap
        libuuid
        linuxHeaders
        pam
        cryptsetup
      ];
      doCheck = false;
      enableParallelBuilding = true;

      # TODO: Honestly; we do not want implicit paths in systemd. we should
      # patch the unit files instead
      patches = [
        ./0001-path-util.h-add-placeholder-for-DEFAULT_PATH_NORMAL.patch
      ];

      postPatch = ''
        substituteInPlace src/basic/path-util.h --replace "@defaultPathNormal@" "${placeholder "out"}/bin/"

      '';

      preConfigure = ''
        for dir in tools src/resolve test src/test; do
          patchShebangs $dir
        done
      '';

      # Tricks systemd in not generating catalog and hwdb.
      # TODO: Actually gneerate these?!
      preInstall = ''
        export DESTDIR=${placeholder "out"}
      '';

      dontAddPrefix = true;

      # Systemd will read units from systemunitdir which is  rootprefixdir+lib/systemd/system
      mesonFlags = [
        "-Dsplit-usr=false" # This just seems to make things more complicated
        "-Dsplit-bin=false"
        "-Dprefix=${placeholder "out"}"
        "-Drootprefix=${placeholder "out"}"
        "-Dsysconfdir=/etc" # NOTE: This is on purpose!!
        "-Dcreate-log-dirs=false"
        "-Dtests=false"
        "-Dinstall-tests=false"
        "-Dsysvinit-path="
        "-Dsysvrcnd-path="
        "-Dldconfig=false"
      ];

      # NOTE: We move $out/$out back to $out do undo the damage that DESTDIR did
      # Note that $out/etc exists already at this point
      postInstall = ''
        # Generate the hwdb.bin file :P
        # TODO: In the future; make hwdb config overridable?

        rm -rf $out/var
        mv $out/$out/* $out
        rm -rf $out/nix
        # rm -rf $out/lib/systemd/tests
      '';

      # NOTE: We should upstream this I guess?

      # Patch dbus and systemd units
      postFixup = ''
        # find $out/share/dbus-1/system-services -type f -name '*.service' -exec \
        # sed -i 's,/bin/false,${coreutils}/bin/false,g' {} \;

        #find $out/lib/systemd/system -type -f -name '*.service' -exec \
        #  sed -i 's,{} ;
      '';
    }
  ) {};
}
