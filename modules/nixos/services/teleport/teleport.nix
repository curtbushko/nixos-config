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
    sops.secrets.teleport_auth_token = {
      sopsFile = ../../../../secrets/secrets.yaml;
      key = "teleport/auth_token";
    };
    sops.age.keyFile = "/home/curtbushko/.config/sops/age/keys.txt";

    # Enable Teleport service
    services.teleport = {
      enable = true;

      settings = {
        teleport = {
          nodename = "gamingrig";
          data_dir = "/var/lib/teleport";
          log = {
            severity = "INFO";
            output = "stderr";
          };
        };

        # Enable auth service (authentication and session recording)
        auth_service = {
          enabled = true;
          listen_addr = "0.0.0.0:3025";
          cluster_name = "gamingrig";

          # Session recording
          session_recording = "node";

          # Authentication settings
          authentication = {
            type = "local";
            second_factors = ["otp"];  # TOTP: Google Authenticator, Authy, 1Password, etc.
          };
        };

        # Enable proxy service (web UI and client access)
        proxy_service = {
          enabled = true;
          listen_addr = "0.0.0.0:3023";
          web_listen_addr = "0.0.0.0:3080";
          tunnel_listen_addr = "0.0.0.0:3024";

          # Public address (adjust if needed)
          public_addr = "gamingrig:3080";
        };

        # Enable SSH service for the local node
        ssh_service = {
          enabled = true;
          labels = {
            role = "server";
            env = "home";
          };
        };
      };
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
