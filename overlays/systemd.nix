final: prev: {
  systemd-tools = prev.systemd.override { withUkify = true; };
}
