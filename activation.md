# Activation pseudocode

Server-optimised linux supports activating new configurations in place.
However; by design it is limited in scope. NixOS' configuration activation
script is a bit of a behemoth that has grown over time and has special cases
and quirks to iron it out. Instead; server-optimised-linux has very strict
rules what _can_ be activated at runtime and what not.  It will also tell you
when it can not fulfill an activation without bugs, and asks you to reboot
instead.

The main rule is:
* Support starting new units
* Support stopping obselete units
* NOT restarting changed units.

The choice of restarting a unit

We start of by calling. which tells us all the units that are known to systemd, and whether they're potentially
masked or not
```
ListUnitFiles
```
We also  call `realpath` on the unit file to get its absolute path in the nix store. If it's not in the nix
store we ignore it for activation and emit a warning "Not managed by nix"

We want to refuse activation if any files that were started before `sysinit.target are changed.
This is a safety precaution;
This is programatically queried using:
```
systemctl show sysinit.target -p After --no-pager
```

the daemon is reloaded to parse all the new config files potentially

Then it will refuse to activate any unit with `DefaultDependencies=no`
and specifically units that are scheduled `Before=sysinit.target`



Next we call `ListUnitFiles` again.
Any unit that disappeared from the list or is now `masked` is stopped.



Next; we go on to starting and restarting. For this we have some more special rules



For all other files; if `realpath` != original realpath; we restart the unit. IF `realpath` didn't point to
a nix store path; we issue a `warning` and don't do anything


Activation is now complete


