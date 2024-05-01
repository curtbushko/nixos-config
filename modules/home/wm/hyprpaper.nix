{
  pkgs,
  lib,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  wallpaper = "/home/curtbushko/wallpapers/cyberpunk_2077_phantom_liberty_katana.jpg";
in {
  home.packages = with pkgs; [
  ]
  ++ (lib.optionals isLinux [
      #pkgs.rofi-firefox-wrapper
    hyprpaper
  ]);

  xdg.configFile."hypr/hyprpaper.conf" = {
    text = ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
    '';
  };
}
