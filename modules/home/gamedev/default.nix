{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.gamedev;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.curtbushko.gamedev = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tools
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      []
      ++ (lib.optionals isLinux [
        aseprite
        audacity
        blender
        # davinci-resolve-studio Disable until https://github.com/NixOS/nixpkgs/issues/341634
        inkscape
        gimp
        krita
        godot_4
        obs-studio
      ]);
  };
}
