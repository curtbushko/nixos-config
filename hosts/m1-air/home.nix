{ inputs, ... }:

{ config, lib, pkgs, ... }:
{
  imports = [
    ./modules/shared/home-manager.nix
  ];
}
