{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.hyprland;
  wallpaper = ../../styles/wallpapers/3440x1440/${config.curtbushko.theme.wallpaper};
in {
  config = mkIf cfg.enable {
    xdg.configFile."hypr/hyprpaper.conf" = {
      text = ''
        preload = ${wallpaper}
        wallpaper = ,${wallpaper}
      '';
    };
    services.hyprpaper.enable = true;
  };
}
