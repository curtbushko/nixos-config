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
            "$HOME/code/go/src/github.com/hashicorp"
            "$HOME/code/go/src/github.com/mitchellh"
            "$HOME/code/go/src/github.com/curtbushko"
          ];
          exact = ["$HOME/.envrc"];
        };
      };
    };
  };
}
