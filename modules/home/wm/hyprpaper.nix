{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm;
  wallpaper = "./../styles/wallpapers/neofusion.jpeg";
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
