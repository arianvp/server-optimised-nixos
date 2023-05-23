self: super: {
  systemd-repart = super.systemdMinimal.overrideAttrs (finalAttrs: previousAttrs: {
    src = super.fetchFromGitHub {
      owner = "systemd";
      repo = "systemd";
      rev = "1eb86ddde4f36165a99732b53cc97cef1acc3aa7";
      hash = "sha256-Frf0QwJCw/fG+YQ/+frqq8aD2Jv32Ozw1JMwjZSBTHc=";
    };

    # Only this patch is necessary to build systemd. This package will not be
    # usable as a general replacement of systemd for NixOS but the tools like
    # systemd-repart will work.
    patches = [ (builtins.elemAt previousAttrs.patches 10) ];
  });
}
