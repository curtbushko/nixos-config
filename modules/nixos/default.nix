{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./pipewire.nix
    ./dbus.nix
    ./fonts.nix
    ./wayland.nix
  ];
}
