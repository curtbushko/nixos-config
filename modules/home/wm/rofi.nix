{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm;
  isLinux = pkgs.stdenv.isLinux;
in {
  config = mkIf cfg.enable {
    programs.rofi = {
      enable = isLinux;
      package = pkgs.rofi-wayland;
      extraConfig = {
        modi = "drun,run";
        show-icons = true;
        case-sensitive = false;
      };
      theme = with config.lib.formats.rasi; {
        "*" = {
          spacing = 0;
          width = mkLiteral "800px";

          #bg = mkLiteral "#${bg}";
          #bg-alt = mkLiteral "#${bg_dark}";
          #fg = mkLiteral "#${fg}";
          #fg-alt = mkLiteral "#${fg_dark}";
          #border-color = mkLiteral "#${blue1}";
          #background-color = mkLiteral "@bg";
          #text-color = mkLiteral "@fg";
        };

        window = {
          transparency = "real";
        };

        mainbox = {
          children = mkLiteral "[inputbar, listview]";
          border = mkLiteral "1px 1px 1px 1px";
        };

        inputbar = {
          #background-color = mkLiteral "@bg-alt";
          children = mkLiteral "[prompt, entry]";
        };

        entry = {
          background-color = mkLiteral "inherit";
          padding = mkLiteral "12px 3px";
        };

        prompt = {
          background-color = mkLiteral "inherit";
          padding = mkLiteral "12px";
        };

        listview = {
          cycle = true;
          lines = mkLiteral "8";
          margin = mkLiteral "0 0 -1px 0";
          scrollbar = false;
        };

        element = {
          children = mkLiteral "[element-icon, element-text]";
        };

        element-icon = {
          padding = mkLiteral "10px 10px";
        };

        element-text = {
          padding = mkLiteral "10px 0";
          #text-color = mkLiteral "@fg-alt";
        };

        "element-text selected" = {
          #text-color = mkLiteral "@fg";
        };
      };
    };
  };
}
