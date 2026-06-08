{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.teleport;
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  config = mkIf cfg.enable {
    # Configure sops to access the teleport auth token
    sops.secrets."teleport/auth_token" = {
      sopsFile = ../../../../secrets/secrets.yaml;
    };
    sops.age.keyFile = "/home/curtbushko/.config/sops/age/keys.txt";

    # Generate teleport config with embedded token using sops template
    sops.templates."teleport.yaml" = {
      content = ''
        version: v3
        teleport:
          nodename: gamingrig
          data_dir: /var/lib/teleport
          log:
            severity: INFO
            output: stderr

        auth_service:
          enabled: true
          listen_addr: "0.0.0.0:3025"
          cluster_name: gamingrig
          tokens:
            - "node:${config.sops.placeholder."teleport/auth_token"}"
          session_recording: node
          authentication:
            type: local
            second_factors:
              - otp

        proxy_service:
          enabled: true
          listen_addr: "0.0.0.0:3023"
          web_listen_addr: "0.0.0.0:3080"
          tunnel_listen_addr: "0.0.0.0:3024"
          public_addr: "gamingrig:3080"

        ssh_service:
          enabled: true
          labels:
            role: server
            env: home
      '';
      path = "/etc/teleport.yaml";
      owner = "root";
      mode = "0600";
    };

    # Enable Teleport service with custom config
    services.teleport = {
      enable = true;
      settings = {};  # Empty - we use sops template instead
    };

    # Override teleport service to use our sops-generated config
    systemd.services.teleport = {
      serviceConfig = {
        ExecStart = lib.mkForce "${pkgs.teleport}/bin/teleport start --config=/etc/teleport.yaml";
      };
      # Ensure sops secrets are available before teleport starts
      after = ["sops-nix.service"];
      wants = ["sops-nix.service"];
    };

    # Open required ports in the firewall
    # Note: The gamingrig config has firewall disabled, but including this for completeness
    networking.firewall.allowedTCPPorts = [
      3023  # Proxy SSH
      3024  # Proxy reverse tunnel
      3025  # Auth server
      3080  # Web UI
    ];
  };
}
