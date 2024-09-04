{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
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
        image = ./wallpapers/alena-aenami-wait.jpg;
        polarity = "dark";
        #base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-terminal-dark.yaml";
        #base16Scheme = "${pkgs.base16-schemes}/share/themes/ashes.yaml";
        base16Scheme = ./tokyo-night-neon.yaml;
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
                package = pkgs.noto-fonts-emoji;
                name = "Noto Color Emoji";
            };
        };
    };
}
