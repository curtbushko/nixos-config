{
  config,
  inputs,
  ...
}: {
  # Keep the login shell path stable across Home Manager generations.
  home.activation.setSteamDeckShell = inputs.home-manager.lib.hm.dag.entryAfter ["installPackages"] ''
    steamdeck_shell="${config.home.profileDirectory}/bin/zsh"
    if [ -z "$DRY_RUN_CMD" ] && [ ! -x "$steamdeck_shell" ]; then
      echo "Cannot set the login shell: $steamdeck_shell is not executable." >&2
      exit 1
    fi

    if ! grep -Fxq "$steamdeck_shell" /etc/shells; then
      printf '%s\n' "$steamdeck_shell" | $DRY_RUN_CMD /usr/bin/sudo tee -a /etc/shells > /dev/null
    fi

    steamdeck_passwd="$(/usr/bin/getent passwd ${config.home.username})"
    if [ "''${steamdeck_passwd##*:}" != "$steamdeck_shell" ]; then
      echo "Setting the Steam Deck login shell to Zsh..."
      $DRY_RUN_CMD /usr/bin/sudo /usr/bin/chsh -s "$steamdeck_shell" ${config.home.username}
    fi
  '';
}
