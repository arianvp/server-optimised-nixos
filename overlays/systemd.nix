self: super: {
  systemd = super.systemd.overrideAttrs (oldAttrs: {
    src = super.fetchFromGitHub {
      owner = "DaanDeMeyer";
      repo = "systemd-stable";
      rev = "repart";
      sha256 = "sha256-6d3/nDPxapL29w+F4ULGKxm4KsAABsr1vYgMT7S94N8=";
    };
  });
}
