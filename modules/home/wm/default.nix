{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    #./rofi.nix
    #./waybar.nix
  ];
}
