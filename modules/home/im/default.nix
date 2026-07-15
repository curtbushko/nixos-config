{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.im;
in {
  options.ns.im = {
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
      # pkgs.wasistlos removed - package was unmaintained and archived upstream
      # Consider using pkgs.karere if needed
      pkgs.whatsapp-emoji-font
    ];
  };
}
