{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.tools;
in {
  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        color = "always";
        style = "numbers,changes";
        italic-text = "always";
      };
      #themes.base16.src = pkgs.writeText "base16.tmTheme" theme.tmTheme;
    };
  };
}
