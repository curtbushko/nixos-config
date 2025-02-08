{
  lib,
  ...
}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.theme = {
    name = mkOption {
      type = with types; enum [
        "andromeda"
        "everforest"
        "gruvbox-material"
        "rebel-scum"
        "tokyo-night-neon"
      ];
      default = "rebel-scum";
      description = ''
        My custom theme to use, sets stylix also
      '';
    };
    wallpaper = mkOption {
      type = with types; nullOr str;
      description = ''
        Wallpaper to use
      '';
    };

  };
  imports = [
    ./stylix.nix
  ];
}
