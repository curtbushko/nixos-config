{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./dbus.nix
    ./fonts.nix
    ./gaming.nix
    ./pipewire.nix
  ];
}
