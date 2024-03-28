{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = {
      primary = {
        mode = "dock";
        layer = "top";
        height = 20;
        margin = "6";
        position = "top";
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
