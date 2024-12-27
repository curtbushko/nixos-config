{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.wm;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    ./hypridle.nix
    ./hyprland.nix
    ./hyprpaper.nix
    ./waybar.nix
    ./rofi.nix
    ./swaylock.nix
  ];

  options.curtbushko.wm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable wm
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

      eww
      swww
      swappy # snapshot tool
      swaybg
      swaylock

      networkmanagerapplet
      dunst
      libnotify
      xdg-utils
    ]);
  };
}
