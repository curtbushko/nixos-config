{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.secrets;
in {
  options.ns.secrets = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable system-level sops secrets on darwin";
    };
  };

  config = mkIf cfg.enable {
    sops.defaultSopsFile = ../../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.keyFile = "/etc/sops/age/keys.txt";

    sops.secrets."OPENCODE_PASSWORD" = {
      sopsFile = ../../../secrets/secrets.env;
      format = "dotenv";
      owner = config.ns.user.name;
    };
  };
}
