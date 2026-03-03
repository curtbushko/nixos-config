{config, lib, pkgs, ...}: let
  # Read colors from flair's style.json in ~/.config/flair/
  # Flair generates base16 colors directly (base00-base0F)
  # Note: Requires --impure flag for nix build/home-manager switch
  flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

  # Default fallback theme (gruvbox-material) if flair style.json doesn't exist
  defaultColors = {
    base00 = "#1d2021";
    base01 = "#282828";
    base02 = "#3c3836";
    base03 = "#504945";
    base04 = "#bdae93";
    base05 = "#d4be98";
    base06 = "#ebdbb2";
    base07 = "#fbf1c7";
    base08 = "#ea6962";
    base09 = "#e78a4e";
    base0A = "#d8a657";
    base0B = "#a9b665";
    base0C = "#89b482";
    base0D = "#7daea3";
    base0E = "#d3869b";
    base0F = "#bd6f3e";
  };

  # Use flair colors if available, otherwise fall back to default
  colors = if builtins.pathExists flairStylePath
           then builtins.fromJSON (builtins.readFile flairStylePath)
           else defaultColors;

  # Strip leading '#' from hex colors for stylix (it expects "1a1b26" not "#1a1b26")
  stripHash = color: lib.removePrefix "#" color;

  # Wallpaper SHA256 hashes
  wallpaperHashes = {
    "firewatch-green.jpg" = "sha256-ILiIAcw9JMHsRNT63TnR3kn1O4IwEliJtb2FwdIQUEM=";
    "cyberpunk-tokyo.png" = lib.fakeHash;
    "cyberpunk_2077_phantom_liberty_katana.jpg" = lib.fakeHash;
    "green-pasture.jpg" = lib.fakeHash;
    "cyberpunk-three.png" = "sha256-9SOiWOXP8Ys/eO0C1KoqKt2pO37qv6gDtkmBwNB/0n0=";
  };

  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/curtbushko/nixos-wallpapers/main/3440x1440/${config.curtbushko.theme.wallpaper}";
    sha256 = wallpaperHashes.${config.curtbushko.theme.wallpaper} or lib.fakeHash;
  };
  isLinux = pkgs.stdenv.isLinux;
in {
  # Base16 guide (https://github.com/chriskempson/base16/blob/main/styling.md)
  # base00 - Default Background
  # base01 - Lighter Background (Used for status bars, line number and folding marks)
  # base02 - Selection Background
  # base03 - Comments, Invisibles, Line Highlighting
  # base04 - Dark Foreground (Used for status bars)
  # base05 - Default Foreground, Caret, Delimiters, Operators
  # base06 - Light Foreground (Not often used)
  # base07 - Light Background (Not often used)
  # base08 - Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
  # base09 - Integers, Boolean, Constants, XML Attributes, Markup Link Url
  # base0A - Classes, Markup Bold, Search Text Background
  # base0B - Strings, Inherited Class, Markup Code, Diff Inserted
  # base0C - Support, Regular Expressions, Escape Characters, Markup Quotes
  # base0D - Functions, Methods, Attribute IDs, Headings
  # base0E - Keywords, Storage, Selector, Markup Italic, Diff Changed
  # base0F - Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
  #
  # Stylix guide (https://stylix.danth.me/styling.html)
  # Background color: base00
  # Alternate background color: base01
  # Main color: base05
  # Alternate main color: base04
  # Red: base08
  # Orange: base09
  # Yellow: base0A
  # Green: base0B
  # Cyan: base0C
  # Blue: base0D
  # Purple: base0E
  # Brown: base0F
  stylix = {
    enable = true;
    #image = ./wallpapers/3440x1440/cyberpunk-tokyo.png;
    #image = ./wallpapers/3440x1440/green_pasture.jpg;
    #image = ./wallpapers/3440x1440/cyberpunk-city-future-digital-art-rq.jpg;
    image = wallpaper;
    polarity = "dark";
    # Flair provides base16 colors with '#' prefix, stylix needs them without
    base16Scheme = {
      base00 = stripHash colors.base00;
      base01 = stripHash colors.base01;
      base02 = stripHash colors.base02;
      base03 = stripHash colors.base03;
      base04 = stripHash colors.base04;
      base05 = stripHash colors.base05;
      base06 = stripHash colors.base06;
      base07 = stripHash colors.base07;
      base08 = stripHash colors.base08;
      base09 = stripHash colors.base09;
      base0A = stripHash colors.base0A;
      base0B = stripHash colors.base0B;
      base0C = stripHash colors.base0C;
      base0D = stripHash colors.base0D;
      base0E = stripHash colors.base0E;
      base0F = stripHash colors.base0F;
    };
    fonts = {
      serif = {
        package = pkgs.fira-code;
        name = "Fira Code";
      };

      sansSerif = {
        package = pkgs.fira-code;
        name = "Fira Code";
      };

      monospace = {
        package = pkgs.fira-code;
        name = "Fira Code";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
    targets.gtk = {
      enable = isLinux;
      extraCss = ''
        /* Reduce spacing in Nautilus icon view */
        .nautilus-canvas-item {
          padding: 2px;
        }

        /* Reduce spacing in Nautilus list view */
        .nautilus-list-view .view {
          padding: 2px;
        }

        /* Reduce icon spacing */
        .nautilus-window flowbox {
          padding: 2px;
        }

        .nautilus-window flowboxchild {
          padding: 2px;
          margin: 2px;
        }
      '';
    };
  };

  # GTK icon theme configuration to fix Vicinae warnings
  gtk = {
    enable = isLinux;
    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons;
    };
  };

  # Add required icon theme packages (Linux only)
  home.packages = with pkgs; lib.optionals isLinux [
    hicolor-icon-theme # Base icon theme
    gruvbox-plus-icons # Main icon theme
  ];

}
