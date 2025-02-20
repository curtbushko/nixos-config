{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.secrets;
in {
  options.curtbushko.secrets = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable secrets
      '';
    };
  };
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.sops
    ];

    sops.defaultSopsFile = ../../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    # this is a little more manual than I'd like but it works and is easy to grow
    # gamingrig secrets
    sops.secrets."hosts/gamingrig/mac_address" = {};
    sops.secrets."hosts/gamingrig/syncthing_id" = {};
    sops.secrets."hosts/gamingrig/tailnet_id" = {};
    # m1 secrets
    sops.secrets."hosts/m1/mac_address" = {};
    sops.secrets."hosts/m1/syncthing_id" = {};
    sops.secrets."hosts/m1/tailnet_id" = {};
    # m1-pro secrets
    sops.secrets."hosts/m1-pro/mac_address" = {};
    sops.secrets."hosts/m1-pro/syncthing_id" = {};
    sops.secrets."hosts/m1-pro/tailnet_id" = {};
    # tailscale secrets
    sops.secrets."tailscale/k8s-oauth/client-id" = {};
    sops.secrets."tailscale/k8s-oauth/client-secret" = {};
    sops.secrets."secrets.env" = {
      path = "${config.xdg.configHome}/env/secrets.env";
      sopsFile = ../../../secrets/secrets.env;
      format = "dotenv";
    };
  };
}
