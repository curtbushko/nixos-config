{pkgs, inputs, ...}: {
  #---------------------------------------------------------------------
  # Tailscale systemd service - Protected from SteamOS updates
  #---------------------------------------------------------------------
  home.activation.setupTailscale = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Remove old override files that conflict with nix-managed service
    if [ -d /etc/systemd/system/tailscaled.service.d ]; then
      echo "Removing conflicting tailscaled service overrides..."
      $DRY_RUN_CMD /usr/bin/sudo rm -rf /etc/systemd/system/tailscaled.service.d
    fi

    # Create systemd service file
    SERVICE_FILE=$(mktemp)
    cat > $SERVICE_FILE << 'EOF'
[Unit]
Description=Tailscale node agent
Documentation=https://tailscale.com/kb/
Wants=network-pre.target
After=network-pre.target NetworkManager.service systemd-resolved.service

[Service]
ExecStart=${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 --tun tailscale0
Restart=on-failure
RuntimeDirectory=tailscale
RuntimeDirectoryMode=0755
StateDirectory=tailscale
StateDirectoryMode=0700
CacheDirectory=tailscale
CacheDirectoryMode=0750
Type=notify

[Install]
WantedBy=multi-user.target
EOF

    # Install service file and protect from updates
    if [ ! -f /etc/systemd/system/tailscaled.service ] || ! diff -q $SERVICE_FILE /etc/systemd/system/tailscaled.service > /dev/null 2>&1; then
      echo "Installing tailscaled system service..."
      $DRY_RUN_CMD /usr/bin/sudo cp $SERVICE_FILE /etc/systemd/system/tailscaled.service
      $DRY_RUN_CMD /usr/bin/sudo chmod 644 /etc/systemd/system/tailscaled.service

      # Protect service from SteamOS updates
      $DRY_RUN_CMD /usr/bin/sudo mkdir -p /etc/atomic-update.conf.d
      echo "/etc/systemd/system/tailscaled.service" | $DRY_RUN_CMD /usr/bin/sudo tee /etc/atomic-update.conf.d/tailscale.conf > /dev/null

      # Enable and restart the service
      $DRY_RUN_CMD /usr/bin/sudo systemctl daemon-reload
      $DRY_RUN_CMD /usr/bin/sudo systemctl enable tailscaled.service
      $DRY_RUN_CMD /usr/bin/sudo systemctl restart tailscaled.service || true
    fi

    rm -f $SERVICE_FILE
  '';
}
