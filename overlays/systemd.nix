self: super: {
  systemd = super.systemd.overridAttrs (old: {
    mesonFlags = old.mesonFlags ++ [
      "-Dhomed=true"
      "-Dportabled=true"
      "-Dsysusers=true"
      "-Dfirstboot=true"
    ];
  });
}
