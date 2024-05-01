{
  pkgs,
  lib,
  ...
}: let

  wallpaper = "/home/curtbushko/wallpapers/cyberpunk_2077_phantom_liberty_katana.jpg";
in {
  home.packages = with pkgs; [
    hyprpaper
  ];

  xdg.configFile."hypr/hyprpaper.conf" = {
    text = ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
    '';
  };
}
