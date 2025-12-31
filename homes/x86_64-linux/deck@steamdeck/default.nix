{
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  ...
}: {
  home.stateVersion = "25.11";
  home.username = "deck";
  home.homeDirectory = "/home/deck";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = true;
    gaming.enable = true;
    git.enable = true;
    programming.enable = false;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools.enable = true;
    wm = {
      tools.enable = false;
      niri.enable = false;
      rofi.enable = false;
    };
    theme = {
      name = "gruvbox-material";
      wallpaper = "cyberpunk-three.png";
    };
  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.cachix
    pkgs.tailscale
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

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

  # Set zsh as default shell
  home.activation.setDefaultShell = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD chsh -s ${pkgs.zsh}/bin/zsh || true
  '';

  #---------------------------------------------------------------------
  # Systemd services - Protected from SteamOS updates
  #---------------------------------------------------------------------
  home.activation.setupTailscale = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create systemd service file
    SERVICE_FILE=$(mktemp)
    cat > $SERVICE_FILE << 'EOF'
[Unit]
Description=Tailscale daemon
Documentation=https://tailscale.com/kb/
After=network-pre.target
Wants=network-pre.target

[Service]
ExecStart=${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state
Restart=on-failure
RuntimeDirectory=tailscale
RuntimeDirectoryMode=0755
StateDirectory=tailscale
StateDirectoryMode=0750
Type=notify

[Install]
WantedBy=multi-user.target
EOF

    # Install service file and protect from updates
    if [ ! -f /etc/systemd/system/tailscaled.service ] || ! diff -q $SERVICE_FILE /etc/systemd/system/tailscaled.service > /dev/null 2>&1; then
      echo "Installing tailscaled system service..."
      $DRY_RUN_CMD sudo cp $SERVICE_FILE /etc/systemd/system/tailscaled.service
      $DRY_RUN_CMD sudo chmod 644 /etc/systemd/system/tailscaled.service

      # Protect service from SteamOS updates
      $DRY_RUN_CMD sudo mkdir -p /etc/atomic-update.conf.d
      echo "/etc/systemd/system/tailscaled.service" | $DRY_RUN_CMD sudo tee /etc/atomic-update.conf.d/tailscale.conf > /dev/null

      # Enable and start the service
      $DRY_RUN_CMD sudo systemctl daemon-reload
      $DRY_RUN_CMD sudo systemctl enable tailscaled.service
      $DRY_RUN_CMD sudo systemctl start tailscaled.service || true
    fi

    rm -f $SERVICE_FILE
  '';

  imports = [
    inputs.stylix.homeModules.stylix
  ];
}
