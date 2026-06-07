{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.curtbushko.nix-cache-gamingrig;
in {
  options.curtbushko.nix-cache-gamingrig = {
    enable = mkEnableOption "Use gamingrig as primary binary cache with wake-on-lan support";

    relayHost = mkOption {
      type = types.str;
      default = "relay";
      description = "Relay host to bounce wake-on-lan through";
    };
  };

  config = mkIf cfg.enable {
    # Install wakeonlan package
    environment.systemPackages = with pkgs; [
      wakeonlan
      etherwake
    ];

    # Create wake script
    environment.etc."nix/wake-gamingrig.sh" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        GAMINGRIG="gamingrig"
        RELAY="${cfg.relayHost}"
        # Read MAC address from environment (set by sops or shell)
        MAC_ADDRESS="''${GAMINGRIG_MAC_ADDRESS:-}"

        # Check if gamingrig is already up
        if ping -c 1 -W 2 "$GAMINGRIG" &>/dev/null; then
          exit 0
        fi

        # Wake gamingrig via relay
        if [ -n "$MAC_ADDRESS" ]; then
          echo "[$(date +%Y-%m-%dT%H:%M:%SZ)] Waking gamingrig via $RELAY..."
          ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
            root@"$RELAY" "etherwake -D -i eth0 '$MAC_ADDRESS'" 2>/dev/null || true

          # Wait for gamingrig to come up (max 60 seconds)
          for i in {1..30}; do
            if ping -c 1 -W 2 "$GAMINGRIG" &>/dev/null; then
              echo "[$(date +%Y-%m-%dT%H:%M:%SZ)] Gamingrig is up"
              exit 0
            fi
            sleep 2
          done
          echo "[$(date +%Y-%m-%dT%H:%M:%SZ)] Warning: gamingrig did not respond after wake"
        fi
      '';
      mode = "0755";
    };

    # Configure Nix to use gamingrig cache with builder
    nix.settings = {
      substituters = [
        "http://gamingrig:5000" # Local cache passthrough (fastest)
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Use gamingrig as remote builder
      builders = [
        "ssh://curtbushko@gamingrig x86_64-linux,armv7l-linux /home/curtbushko/.ssh/id_ed25519 8 - nixos-test,benchmark,big-parallel,kvm"
      ];
      builders-use-substitutes = true;
    };

    # Systemd service to wake gamingrig before nix operations
    systemd.services.wake-gamingrig-on-boot = {
      description = "Wake gamingrig on boot for Nix cache access";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/etc/nix/wake-gamingrig.sh";
        RemainAfterExit = false;
        EnvironmentFile = "/run/secrets/secrets.env";  # Load GAMINGRIG_MAC_ADDRESS from sops
      };
    };
  };
}
