{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.wm.tools;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    ./hyprland/hypridle.nix
    ./hyprland/hyprland.nix
    ./hyprland/hypr-waybar.nix
    ./rofi.nix
    ./hyprland/hyprpaper.nix
    ./niri/niri.nix
    ./niri/niri-waybar.nix
    ./niri/swayidle.nix
  ];

  options.curtbushko.wm.tools = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable wm tools
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
      ]
      ++ (lib.optionals isLinux [
        brightnessctl
        cliphist
        grim
        slurp
        wl-clipboard
        wl-clip-persist
        pavucontrol

        eww
        swww
        swappy # snapshot tool

        networkmanagerapplet
        dunst
        libnotify
        xdg-utils
        xwayland-satellite
      ]);
  };
}
