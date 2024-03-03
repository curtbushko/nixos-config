{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyperland.nix
    ./wayland.nix
    ./pipewire.nix
    ./dbus.nix
    ./fonts.nix
  ];
}
