# Server-optimised NixOS

I wanted a playground to play around ideas to 'modernise' NixOS.
For now, that's easier with a from scratch approach where I can
freely sketch out ideas.

Server-optimised NixOS is a distribution inspired
by  NixOS, ChromeOS, Container Optimised Linux and  Container Linux.

It is an opinionated, server-first distribution.

## Features
* Automatic updates
* Bring your own pkgs.  Meaning no more `blah.package` setting in modules. Modules are purely config, not an override for packages.
* Atomic upgrades and rollbacks through reboots or kexec
* No GUI components
* Have to include modules on demand.
* Heavily documented modules
* Systemd is used for both stage-1 and stage-2 init
* Systemd-networkd based networking
* Systemd-nspawn based containers (and also docker containers)
* Alas _no_ systemd-boot as literally no hosting provider supports EFI
* Heavy use of systemd-generators
* Uses systemd-tmpfiles to populate `/etc`
* Systemd resizes and formats disks on first boot
- 
