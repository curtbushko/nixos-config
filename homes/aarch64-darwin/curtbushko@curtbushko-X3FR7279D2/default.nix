{
  pkgs,
  inputs,
  ...
}: {
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "18.09";

  # Let home manager manage itself
  programs.home-manager.enable = true;
  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options
  #---------------------------------------------------------------------
  curtbushko = {
    cron = {
      enable = true;
      killExchangeProcesses.enable = true;
    };
    git.enable = true;
    k8s.enable = true;
    programming.enable = true;
    scripts.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools = {
      enable = true;
      teleport.enable = true;
    };
    llm.enable = true;
    wm.rectangle.enable = true;
    # Theme colors managed by flair: run `flair select <theme>`
    theme.wallpaper = "green-pasture.jpg";

  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    # Darwin only
    pkgs.cachix
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.podman
    pkgs.python312
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenv
    pkgs.pre-commit
    pkgs.terraform
    pkgs.kubernetes-helm
    pkgs.awscli2
    pkgs.obsidian
    pkgs.wakeonlan  # For wake-on-lan
  ];

  # Wake-on-lan script for gamingrig (on LAN, use wakeonlan directly)
  home.file.".local/bin/wake-gamingrig" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      GAMINGRIG="gamingrig"
      MAC_ADDRESS="''${GAMINGRIG_MAC_ADDRESS:-}"

      # Check if gamingrig is already up
      if ping -c 1 -W 2 "$GAMINGRIG" &>/dev/null; then
        echo "Gamingrig is already up"
        exit 0
      fi

      # Wake gamingrig using wakeonlan (m1-pro is on LAN)
      if [ -n "$MAC_ADDRESS" ]; then
        echo "[$(date +%Y-%m-%dT%H:%M:%SZ)] Waking gamingrig (LAN)..."
        wakeonlan "$MAC_ADDRESS" 2>/dev/null || true

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
  };

  imports = [
    inputs.stylix.homeModules.stylix
  ];
}
