final: prev: {
  systemd-sysusers = prev.systemd.overrideAttrs (finalAttrs: previousAttrs: {
    mesonFlags = previousAttrs.mesonFlags ++ [ "-Dsysusers=true" ];
  });
  systemd-tools = ((prev.systemd.override { withUkify = true; }).overrideAttrs (finalAttrs: previousAttrs: {
    src = prev.fetchFromGitHub {
      owner = "systemd";
      repo = "systemd-stable";
      rev = "v253.6";
      hash = "sha256-LZs6QuBe23W643bTuz+MD2pzHiapsBJBHoFXi/QjzG4=";
    };
    patches = [ (builtins.elemAt previousAttrs.patches 9) ];
  }));
}
