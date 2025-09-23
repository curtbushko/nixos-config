{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global = {
          warn_timeout = 0;
        };
        whitelist = {
          prefix = [
            "$HOME/workspace/github.com/hashicorp"
            "$HOME/workspace/github.com/mitchellh"
            "$HOME/workspace/github.com/curtbushko"
          ];
          exact = ["$HOME/.envrc"];
        };
      };
    };
  };
}
