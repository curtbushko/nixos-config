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
    "alone-cyberpunk-morning-4k-xi.jpg" = "sha256-zITr4RYr637YrnPq+crzjiW3DKs890oQBGJyV/7UahE=";
    "cyber-futuristic-city-fantasy-art-4k-da.jpg" = "sha256-Qcqo6bVCAGOLifWs4sZo4sT1BXgMeNjThd+U9Fb65q0=";
    "cyberpunk-2077-phantom-liberty-t7.jpg" = "sha256-tgs1ggqJiC7XjPI3hjoBPuWmxj2ZOQhcJ1GTtP8DJgs=";
    "cyberpunk-city-future-digital-art-rq.jpg" = "sha256-KpiuK1txsP14r0WdkWcRkTYOdU1c7FMeBO6Veci3nV8=";
    "cyberpunk-city-night-view-4k.jpg" = "sha256-eZYu08R2Mqj8tYYAC5B6l7gj8VbrMA8t2V2MGzCDV00=";
    "cyberpunk-street-neon-abstract-triangle-art-5k.jpg" = "sha256-waUn2CKr5abvkb2EJqhoiFuzWr/apbxa9YFdqoSDIXQ=";
    "cyberpunk-three.png" = "sha256-9SOiWOXP8Ys/eO0C1KoqKt2pO37qv6gDtkmBwNB/0n0=";
    "cyberpunk-tokyo.png" = "sha256-EF0HC5xMSzfumSsgyCaR7qYvT18eQQQMoG4BhZfrrq0=";
    "cyberpunk-two.png" = "sha256-qPA9pua8SI8yN0UYZFN6zEID7UlJNg9kqKl5498kW1w=";
    "cyberpunk_2077_phantom_liberty_katana.jpg" = "sha256-j4lo10bA9IT/qVE6LrFXbT6Gc85LYcS9xvMeeoEjq3U=";
    "exploring_new_worlds.jpg" = "sha256-AUEsll/1ukR/CgAE09no9KPSNLmXN8jCaWJBEe3l6XY=";
    "firewatch-blue.png" = "sha256-le8ue1DIBQToLBgXgX+72LKC3wWzNqWFYClIACYpsoY=";
    "firewatch-green.jpg" = "sha256-ILiIAcw9JMHsRNT63TnR3kn1O4IwEliJtb2FwdIQUEM=";
    "firewatch-mountain.jpeg" = "sha256-aybcH2pZDgvvZ2pIQiI/gpwc9t9OUaCjBHecJ4Xzsdw=";
    "firewatch.png" = "sha256-yQSLWwX/fYpd8B9RwrLqX0DCxpeLKWmGLjOQ2PlDOyA=";
    "green-pasture.jpg" = "sha256-fZXr148Y6LtvzbyuT1JiWsWtwOH0r1AUiZhX78Sd54Y=";
    "my-city-gx.jpg" = "sha256-TKU4weRUuP+ZYSVmmBCRotB3PWp5grU2lvGV1Uallxs=";
    "nebula.jpeg" = "sha256-S2X51R4dTBKCtlMvvNrA+bFqMA8h75g+N9GeoQe9gRY=";
    "neofusion.jpeg" = "sha256-dzcg5kjEdLJ8W0GQETzf+66jcZzwC3Q3URBYe2ftXHk=";
    "nightsky.jpeg" = "sha256-InV8IrD+1q5DN8S7/SXZZslTmCSQ/kLvxcURc3AWpCA=";
    "redplanet.png" = "sha256-hMc7W2iJ0FL8Pv21B/1X8Y7Gxe+DpCQF0LhqXnUaagw=";
    "space-cloud.jpg" = "sha256-heFPWu3dT4eH9qgObLtP4t8sZFZ+I+/B5ia2pmgkIlg=";
    "tree.png" = "sha256-Ym0n19JAYvJGFypOJStEffQYkaNG+2MnPaioKaDnsyA=";
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
