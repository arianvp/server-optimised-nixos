/*
This module provides a minimal distribution that has some basic
default modules imported and config enabled.
*/
{ pkgs, lib, options, ...}:
{
  imports = [ ../modules/base.nix ];
  options = {};
  config = {
  };
}
