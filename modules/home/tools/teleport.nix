{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
  cfg = config.curtbushko.tools.teleport;
  secretsEnabled = config.curtbushko.secrets.enable;
  isDarwin = pkgs.stdenv.isDarwin;
in {
  options.curtbushko.tools.teleport = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Teleport client tools (tsh, tctl)
      '';
    };

    proxyAddr = mkOption {
      type = types.str;
      default = "gamingrig:3080";
      description = ''
        Teleport proxy address (hostname:port)
      '';
    };

    clusterName = mkOption {
      type = types.str;
      default = "gamingrig";
      description = ''
        Teleport cluster name
      '';
    };
  };

  config = mkIf (cfg.enable && secretsEnabled) {
    # Install Teleport client package (includes tsh, tctl)
    home.packages = [
      pkgs.teleport
    ];

    # Define the teleport auth token secret
    sops.secrets."teleport/auth_token" = {};

    # Create teleport client configuration using sops template
    sops.templates."teleport-config" = {
      content = ''
        version: v3
        teleport:
          auth_token: ${config.sops.placeholder."teleport/auth_token"}
          proxy_server: ${cfg.proxyAddr}
        auth_service:
          enabled: false
        ssh_service:
          enabled: true
        proxy_service:
          enabled: false
      '';
      path = "${config.xdg.configHome}/teleport/teleport.yaml";
    };

    # Create tsh config directory
    home.file."${config.xdg.configHome}/tsh/.keep".text = "";

    # Add shell aliases for convenience
    home.shellAliases = {
      tsh-login = "tsh login --proxy=${cfg.proxyAddr} --user=\${USER}";
      tsh-ls = "tsh ls";
      tsh-ssh = "tsh ssh";
    };

    # Add tsh completion to bash/zsh if enabled
    programs.bash.initExtra = mkIf config.programs.bash.enable ''
      # Teleport (tsh) shell completion
      if command -v tsh &> /dev/null; then
        source <(tsh --completion-script-bash)
      fi
    '';

    programs.zsh.initExtra = mkIf config.programs.zsh.enable ''
      # Teleport (tsh) shell completion
      if command -v tsh &> /dev/null; then
        source <(tsh --completion-script-zsh)
      fi
    '';

    # macOS-specific: Install and trust Teleport CA certificate
    home.file.".teleport-ca.crt" = mkIf isDarwin {
      source = ../../../../secrets/teleport-ca.crt;
    };

    home.activation.trustTeleportCert = mkIf isDarwin (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        CERT_PATH="$HOME/.teleport-ca.crt"
        CERT_NAME="Teleport gamingrig CA"

        # Check if certificate exists and is already trusted
        if [ -f "$CERT_PATH" ]; then
          # Remove old certificate if it exists
          $DRY_RUN_CMD sudo /usr/bin/security delete-certificate -c "$CERT_NAME" /Library/Keychains/System.keychain 2>/dev/null || true

          # Add certificate to system keychain and trust it for SSL
          $DRY_RUN_CMD sudo /usr/bin/security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_PATH"

          echo "Teleport CA certificate installed and trusted in system keychain"
        fi
      ''
    );
  };
}
