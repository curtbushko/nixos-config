{
  config,
  lib,
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    ./hyprland.nix
    ./hypridle.nix
    ./waybar.nix
    ./rofi.nix
  ];

  home.packages = with pkgs;
    [
    ]
    ++ (lib.optionals isLinux [
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
    ]);
}
