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
      config = {
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
