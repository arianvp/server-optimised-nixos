# Server-optimised NixOS

I wanted a playground to play around ideas to 'modernise' NixOS.
For now, that's easier with a from scratch approach where I can
freely sketch out ideas.

Server-optimised NixOS is a distribution inspired
by  NixOS, ChromeOS, Container Optimised Linux and  Container Linux.

It is an opinionated, server-first distribution.

Note that most of the listed features are currently vaporware

## Running
You can spawn a QEMU for now:
```
$(nix-build -A config.systemd.build.runvm)
```

## Features
* Automatic updates
* Bring your own pkgs.  Meaning no more `blah.package` setting in modules. Modules are purely config, not an override for packages.
  * Does away with the `nixpkgs` module. and the `system` parameter
* Unattended reboots
* Atomic upgrades and rollbacks through reboots or kexec\
  * Automatic boot assessment through systemd-boot with automatic rollback when system is unhealthy
* No GUI components
* fwupd integration
* Have to include modules on demand.
* Heavily documented modules
* Systemd is used for both stage-1 and stage-2 init
* Systemd-networkd based networking
* Systemd-nspawn based containers (and also docker containers)
* Heavy use of systemd-generators
* Uses systemd-tmpfiles to populate `/etc`
* Systemd resizes and formats disks on first boot
* Only use ``Requires and Wants. Not WantedBy and RequiresBy
   i.e.

   targets.multi-user.wants = [ "nginx.service" ];

   instead of    services.nginx.wantedBy = [ "multi-user.target" ];


   Why? This makes me less confused about ordering. Arrows are hard

* Initrd can reconfigure the system (by consulting cloud-metadata or matchbox-like system)
  * https://github.com/coreos/afterburn
  * https://coreos.com/matchbox/docs/latest/api.html
  * https://github.com/poseidon/matchbox
  * https://github.com/coreos/ignition

## About my current gripes with NixOS "cloud" images

NixOS ships a bunch of cloud images; Azure, AWS, Digitalocean, GCP.
These support reconfiguring boxes through contacting metadata service and then nixos-rebuild'switching into
the desired configuration.

I guess this works 'fine'.

## TODOs:

* Make kernel-install optional through mesonFlags instead of hacky patch
* Something with modulesTree so that depMod actually works!
* microcode
* Make an initramfs optional?

