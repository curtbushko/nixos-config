{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.user;
in {
  options.ns.user = {
    name = mkOption {
      type = types.str;
      description = "Primary user name for this darwin system";
    };
    home = mkOption {
      type = types.str;
      default = "/Users/${cfg.name}";
      description = "Home directory for the primary user";
    };
  };

  config = {
    system.primaryUser = cfg.name;
    users.users.${cfg.name} = {
      home = cfg.home;
      shell = pkgs.zsh;
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        cleanup = "zap";
        upgrade = false;
      };
      brews = [];
      taps = [];
      casks = [
        "obs"
        "rectangle"
        "slack"
        "vlc"
        "notunes"
      ];
    };
  };
}
