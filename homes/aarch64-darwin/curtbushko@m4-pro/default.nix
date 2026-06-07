{
  pkgs,
  inputs,
  ...
}: {
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";

  # Let home manager manage itself
  programs.home-manager.enable = true;
  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = true;
    cron.enable = true;
    gaming.enable = true;
    git.enable = true;
    k8s.enable = true;
    llm = {
      enable = true;
      # Model configuration for Qwen (GGUF for llama-cpp)
      models.qwen = {
        enable = true;
        autoDownload = false;  # Download manually to avoid timeout
      };
    };
    programming.enable = true;
    scripts.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools = {
      enable = true;
      teleport.enable = true;
    };
    wm.rectangle.enable = true;
    # Theme colors managed by flair: run `flair select <theme>`
    theme.wallpaper = "cyberpunk_2077_phantom_liberty_katana.jpg";
  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    # Darwin only
    pkgs.cachix
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.podman
    pkgs.obsidian
    pkgs.wakeonlan  # For wake-on-lan
  ];

  # Wake-on-lan script for gamingrig (bounce off relay via Tailscale)
  home.file.".local/bin/wake-gamingrig" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      GAMINGRIG="gamingrig"
      RELAY_TAILNET_ID="''${RELAY_TAILNET_ID:-relay}"
      MAC_ADDRESS="''${GAMINGRIG_MAC_ADDRESS:-}"

      # Check if gamingrig is already up
      if ping -c 1 -W 2 "$GAMINGRIG" &>/dev/null; then
        echo "Gamingrig is already up"
        exit 0
      fi

      # Wake gamingrig by bouncing off relay via Tailscale
      if [ -n "$MAC_ADDRESS" ]; then
        echo "[$(date +%Y-%m-%dT%H:%M:%SZ)] Waking gamingrig via $RELAY_TAILNET_ID..."
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
          root@"$RELAY_TAILNET_ID" "etherwake -D -i eth0 '$MAC_ADDRESS'" 2>/dev/null || true

        # Wait for gamingrig to come up
        for i in {1..30}; do
          if ping -c 1 -W 2 "$GAMINGRIG" &>/dev/null; then
            echo "[$(date +%Y-%m-%dT%H:%M:%SZ)] Gamingrig is up"
            exit 0
          fi
          sleep 2
        done
        echo "[$(date +%Y-%m-%dT%H:%M:%SZ)] Warning: gamingrig did not respond after wake"
      else
        echo "Error: GAMINGRIG_MAC_ADDRESS not set in environment"
        exit 1
      fi
    '';
  };

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    TERM = "xterm-ghostty";
    QT_QPA_PLATFORMTHEME = "kde";
  };

  imports = [
    inputs.stylix.homeModules.stylix
  ];
}
