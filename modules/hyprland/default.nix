{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    ./wayland.nix
    ./pipewire.nix
    ./dbus.nix
    ./fonts.nix
  ];
}
