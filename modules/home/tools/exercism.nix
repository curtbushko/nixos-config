{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
  secretsEnabled = config.curtbushko.secrets.enable;
in {
  config = mkIf (cfg.enable && secretsEnabled) {
    home.packages = [
      pkgs.exercism
    ];

    # Define the exercism token secret
    sops.secrets."exercism/token" = {};

    # Use sops templates to create the config file with the secret
    sops.templates."exercism-config" = {
      content = builtins.toJSON {
        apibaseurl = "https://api.exercism.io/v1";
        token = config.sops.placeholder."exercism/token";
        workspace = "/home/curtbushko/workspace/github.com/curtbushko/leetcode/exercism";
      };
      path = "${config.xdg.configHome}/exercism/user.json";
    };
  };
}
