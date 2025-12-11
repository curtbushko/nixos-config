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
    ./cliphist.nix
    ./filebrowser.nix
    ./rofi.nix
    ./niri.nix
    ./swaybg.nix
    ./swayidle.nix
    ./vicinae.nix
    ./waybar.nix
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
        lxqt.pavucontrol-qt

        eww
        swww
        swappy # snapshot tool

        mako
        networkmanagerapplet
        libnotify
        xdg-utils
        xwayland-satellite
      ]);

    home.pointerCursor = {
      name = "BreezeX-RosePine-Linux";
      package = pkgs.rose-pine-cursor;
      size = 32;
      x11.enable = isLinux;
      gtk.enable = isLinux;
    };
  };
}
