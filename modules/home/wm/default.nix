{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./wayland.nix
    ./rofi.nix
  ];

  home.packages = with pkgs; [
    brightnessctl
    cliphist
    grim
    slurp
    wl-clipboard

    eww-wayland
    swww
    swappy # snapshot tool
    swaybg

    networkmanagerapplet
    dunst
    libnotify
    xdg-utils
  ];
}
