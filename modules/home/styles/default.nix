{
  lib,
  ...
}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.theme = {
    name = mkOption {
      type = with types; enum [
        "rebel-scum"
        "tokyo-night-neon"
      ];
      default = "rebel-scum";
      description = ''
        My custom theme to use, sets stylix also 
      '';
    };
  };
  imports = [
    ./stylix.nix
  ];
}
