{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.im;
in {
  options.curtbushko.im = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable instant messaging tools
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.wasistlos
      pkgs.whatsapp-emoji-font
    ];
  };
}
