# Server-optimised NixOS

I wanted a playground to play around ideas to 'modernise' NixOS.
For now, that's easier with a from scratch approach where I can
freely sketch out ideas.

Server-optimised NixOS is a distribution inspired
by  NixOS, ChromeOS, Container Optimised Linux and  Container Linux.

It is an opinionated, server-first distribution.

Note that most of the listed features are currently vaporware


## Running

* You can build an EFI image

  ```bash
  nix build .#image
  ```

* Build a bootspec

  ```bash
  nix build .#toplevel
  ```


* Run with MacOS 'Virtualization.Framework':

  We can't provide a nix package until Apple SDK 12 is shipped. tracked here https://github.com/NixOS/nixpkgs/issues/242666

  ```bash
  nix build .#toplevel --eval-store auto --builder ssh://linux-builder
  nix run . ./result/boot.json
  ```


## Features

* Automatic updates
* Measured boot (TPM)
* [x] systemd-boot with Unified Kernel images
* [ ] SecureBoot
* [x] Using   dm-verity for integrity of the system
* Unattended reboots
* Atomic upgrades and rollbacks through reboots or kexec\
  * Automatic boot assessment through systemd-boot with automatic rollback when system is unhealthy
* No GUI components
* fwupd integration
* Have to include modules on demand.
* Heavily documented modules
* [x] Systemd is used for both stage-1 and stage-2 init
* [x] Systemd-networkd based networking
* Systemd-nspawn based containers (and also docker containers)
* Heavy use of systemd-generators
* Uses systemd-tmpfiles to populate `/etc`
* [x] Systemd resizes and formats disks on first boot using `systemd-repart`
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

## Boot process

![Screenshot](plot.svg)

systemConfig can either be a path to an evaluated thingy or a path to a nix expression

systemd initrd is booted.

Might need to patch `systemd/remount-fs/remount-fs.c`.  /usr and / are treated
special by systemd and will be remounted in stage-2 with the correct /etc/fstab options.

Why /usr too is a mystery to me; as the only way to mount it is by


```
# FIXME when linux < 4.5 is EOL, switch to atomic bind mounts
#mount /nix/store /nix/store -o bind,remount,ro
mount --bind /nix/store /nix/store
mount -o remount,ro,bind /nix/store
```


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

