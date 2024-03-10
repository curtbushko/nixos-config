{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
          "hyprland/submap"
          "pulseaudio"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "network"
          "cpu"
          "memory"
          "temperature"
          "tray"
        ];
      };
    };
  };
}
