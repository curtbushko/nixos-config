{
  config,
  inputs,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  loaderVersion = "3.3.1";
  pluginVersion = "0.8.0";
  loader = pkgs.fetchurl {
    name = "decky-loader-${loaderVersion}";
    url = "https://github.com/SteamDeckHomebrew/decky-loader/releases/download/v${loaderVersion}/PluginLoader";
    hash = "sha256-e7c7BQLEnnGU80+c5N22d3dk6Sd9el5UZl9mRg1QwxU=";
  };
  pluginZip = pkgs.fetchurl {
    name = "unifideck-${pluginVersion}.zip";
    url = "https://github.com/mubaraknumann/unifideck/releases/download/Release-${pluginVersion}/unifideck.prod.v${pluginVersion}.zip";
    hash = "sha256-b+ekVm5wGtpk87yQzRSPpOQuOyPlyuc2G5WAMrLhHSA=";
  };
  plugin = pkgs.runCommand "unifideck-${pluginVersion}" {nativeBuildInputs = [pkgs.unzip];} ''
    unzip -q ${pluginZip} -d unpack
    test -f unpack/Unifideck/plugin.json
    test -f unpack/Unifideck/main.py
    mkdir -p "$out"
    cp -a unpack/Unifideck/. "$out/"
    chmod -R a+rX "$out"
    find "$out/bin" -type f -exec chmod a+x {} +
  '';
  # Matches upstream's release service; binaries stay mutable for Decky's runtime.
  service = pkgs.writeText "plugin_loader.service" ''
    [Unit]
    Description=SteamDeck Plugin Loader
    After=network.target
    [Service]
    Type=simple
    User=root
    Restart=always
    KillMode=process
    TimeoutStopSec=15
    ExecStart=${home}/homebrew/services/PluginLoader
    WorkingDirectory=${home}/homebrew/services
    Environment=UNPRIVILEGED_PATH=${home}/homebrew
    Environment=PRIVILEGED_PATH=${home}/homebrew
    Environment=LOG_LEVEL=INFO
    [Install]
    WantedBy=multi-user.target
  '';
in {
  home.activation.installDecky = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -n "$DRY_RUN_CMD" ]; then
      echo "Would install Decky Loader ${loaderVersion} and Unifideck ${pluginVersion} (requires sudo)."
    else (
      set -euo pipefail
      decky_home="${home}/homebrew"
      decky_unit=/etc/systemd/system/plugin_loader.service
      decky_plugin="$decky_home/plugins/Unifideck"
      decky_changed=false
      plugin_changed=false
      if ! cmp -s ${loader} "$decky_home/services/PluginLoader" || ! cmp -s ${service} "$decky_unit"; then
        decky_changed=true
      fi
      if [ ! -f "$decky_plugin/.nix-source" ] || [ "$(cat "$decky_plugin/.nix-source")" != "${plugin}" ] || ! cmp -s ${plugin}/plugin.json "$decky_plugin/plugin.json"; then
        plugin_changed=true
      fi

      mkdir -p "${home}/.steam/steam"
      touch "${home}/.steam/steam/.cef-enable-remote-debugging"
      /usr/bin/sudo mkdir -p "$decky_home/services" "$decky_home/plugins" "$decky_home/.trash"
      /usr/bin/sudo chown ${config.home.username}:${config.home.username} "$decky_home" "$decky_home/services" "$decky_home/plugins"

      if $decky_changed || $plugin_changed; then
        decky_archive="$(/usr/bin/sudo mktemp -d "$decky_home/.trash/decky.XXXXXXXX")"
        if $plugin_changed; then
          decky_staging="$(/usr/bin/sudo mktemp -d "$decky_home/plugins/.Unifideck.XXXXXXXX")"
          /usr/bin/sudo cp -a ${plugin}/. "$decky_staging/"
          /usr/bin/sudo chmod -R u+w,a+rX "$decky_staging"
          if [ -f "$decky_plugin/config.json" ]; then
            /usr/bin/sudo cp -a "$decky_plugin/config.json" "$decky_staging/config.json"
          fi
          printf '%s\n' '${plugin}' | /usr/bin/sudo tee "$decky_staging/.nix-source" > /dev/null
          /usr/bin/sudo chown -R ${config.home.username}:${config.home.username} "$decky_staging"
        fi

        # Restart the old service on failure; never discard existing plugin files.
        decky_stopped=false
        trap 'if $decky_stopped; then /usr/bin/sudo systemctl start plugin_loader.service; fi' EXIT
        if /usr/bin/sudo systemctl is-active --quiet plugin_loader.service; then
          /usr/bin/sudo systemctl stop plugin_loader.service
          decky_stopped=true
        fi
        if $decky_changed; then
          if [ -e "$decky_home/services/PluginLoader" ]; then
            /usr/bin/sudo cp -a "$decky_home/services/PluginLoader" "$decky_archive/PluginLoader"
          fi
          if [ -e "$decky_unit" ]; then
            /usr/bin/sudo cp -a "$decky_unit" "$decky_archive/plugin_loader.service"
          fi
          /usr/bin/sudo install -m 0755 ${loader} "$decky_home/services/PluginLoader"
          printf 'v%s\n' '${loaderVersion}' | /usr/bin/sudo tee "$decky_home/services/.loader.version" > /dev/null
          /usr/bin/sudo install -m 0644 ${service} "$decky_unit"
        fi
        if $plugin_changed; then
          if [ -e "$decky_plugin" ] || [ -L "$decky_plugin" ]; then
            /usr/bin/sudo mv "$decky_plugin" "$decky_archive/Unifideck"
          fi
          /usr/bin/sudo mv "$decky_staging" "$decky_plugin"
        fi
        /usr/bin/sudo systemctl daemon-reload
        /usr/bin/sudo systemctl restart plugin_loader.service
        decky_stopped=false
        echo "Installed Decky Loader ${loaderVersion} and Unifideck ${pluginVersion}; backups: $decky_archive"
        echo "Restart Steam or return to Gaming Mode to load Decky."
      fi
      /usr/bin/sudo systemctl enable --now plugin_loader.service
    )
    fi
  '';
}
