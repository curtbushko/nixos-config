{
  lib,
  ...
}: let
  inherit (lib) types mkOption;
in {
  # Theme colors are now managed by flair (~/.config/flair/style.json)
  # Run: flair select <theme-name> to switch themes
  options.curtbushko.theme = {
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
