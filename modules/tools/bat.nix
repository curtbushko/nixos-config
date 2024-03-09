{
  config,
  lib,
  pkgs,
  theme,
  ...
}: {

  programs.bat = {
    enable = true;
    config = {
      theme  = "base16";
      color = "always";
      style = "numbers,changes";
      italic-text = "always";
    };
    themes.base16.src = pkgs.writeText "base16.tmTheme" theme.tmTheme;
  };
}
