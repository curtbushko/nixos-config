{...}: let
  wallpaper = "./../styles/wallpapers/neofusion.jpeg";
in {
  xdg.configFile."hypr/hyprpaper.conf" = {
    text = ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
    '';
  };
  services.hyprpaper.enable = true;
}
