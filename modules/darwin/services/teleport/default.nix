{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types mkEnableOption;
  cfg = config.curtbushko.services.teleport;

  # Generate teleport config file template
  teleportConfig = pkgs.writeText "teleport.yaml" ''
    version: v3
    teleport:
      nodename: ${config.networking.hostName}
      data_dir: /var/lib/teleport
      auth_token: AUTH_TOKEN_PLACEHOLDER
      proxy_server: ${cfg.proxyServer}
      log:
        severity: ${cfg.logLevel}
        output: stderr
    auth_service:
      enabled: false
    proxy_service:
      enabled: false
    ssh_service:
      enabled: true
      labels:
        env: ${cfg.labels.env}
        os: darwin
        hostname: ${config.networking.hostName}
  '';
in {
  imports = [
    inputs.sops-nix.darwinModules.sops
  ];

  options.curtbushko.services.teleport = {
    enable = mkEnableOption "Teleport node service";

    proxyServer = mkOption {
      type = types.str;
      default = "gamingrig:3080";
      description = "Teleport proxy server address";
    };

    ageKeyFile = mkOption {
      type = types.str;
      default = "/Users/curtbushko/.config/sops/age/keys.txt";
      description = "Path to the age key file for sops decryption";
    };

    logLevel = mkOption {
      type = types.enum ["DEBUG" "INFO" "WARN" "ERROR"];
      default = "INFO";
      description = "Teleport log level";
    };

    labels = {
      env = mkOption {
        type = types.str;
        default = "home";
        description = "Environment label for this node";
      };
    };
  };

  config = mkIf cfg.enable {
    # Configure sops to access the teleport auth token
    sops.secrets.teleport_auth_token = {
      sopsFile = ../../../../secrets/secrets.yaml;
      key = "teleport/auth_token";
    };
    sops.age.keyFile = cfg.ageKeyFile;

    # Install teleport package
    environment.systemPackages = [pkgs.teleport];

    # Run teleport as a launchd daemon
    launchd.daemons.teleport = {
      path = [pkgs.coreutils pkgs.gnused];

      # Script that creates data dir, substitutes the auth token, and runs teleport
      script = ''
        # Ensure data directory exists (activation scripts unreliable on darwin)
        mkdir -p /var/lib/teleport
        chmod 700 /var/lib/teleport

        AUTH_TOKEN=$(cat ${config.sops.secrets.teleport_auth_token.path})
        CONFIG_DIR="/var/lib/teleport"
        CONFIG_FILE="$CONFIG_DIR/teleport.yaml"

        # Create config with actual token
        sed "s|AUTH_TOKEN_PLACEHOLDER|$AUTH_TOKEN|g" ${teleportConfig} > "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"

        exec ${pkgs.teleport}/bin/teleport start --config="$CONFIG_FILE"
      '';

      serviceConfig = {
        Label = "org.nixos.teleport";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/teleport.log";
        StandardErrorPath = "/var/log/teleport.error.log";
      };
    };
  };
}
