# This module re-exports the care module
{ config, lib, pkgs, ... }:

{
  imports = [ ./care.nix ];
}
