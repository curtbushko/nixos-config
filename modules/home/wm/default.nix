{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard

    eww-wayland
    swww

    networkmanagerapplet

    rofi-wayland
    wofi
  ];
}
