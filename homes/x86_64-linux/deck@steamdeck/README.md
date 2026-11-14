# Steam Deck

This is a standalone Home Manager configuration on SteamOS, not NixOS.
System changes during activation require `deck` to have working sudo access.

## Decky Loader and Unifideck

`decky.nix` pins Decky Loader 3.3.1 and Unifideck 0.8.0 release artifacts with
SHA-256 hashes. Home Manager activation installs Decky's `plugin_loader.service`,
enables Steam's CEF remote-debugging flag required by Decky, and copies the
Unifideck plugin into `~/homebrew/plugins/Unifideck`.

Decky runs as root, matching upstream's service. Install only trusted plugins.
The upstream binaries target SteamOS; Nix verifies/downloads them but does not
rebuild them from source. This configuration is specific to the x86_64 Steam Deck.

After applying on the Deck, restart Steam or return to Gaming Mode. Open Decky
from the Quick Access menu to find Unifideck. Store sign-in and Xbox Cloud Gaming
require Microsoft Edge; follow Unifideck's installation prompt if it is missing.
Store authentication and game installation remain interactive.

Plugin files stay writable because Decky and Unifideck expect a mutable install.
Accounts, games, `~/.local/share/unifideck`, and Decky's settings directory are not
managed by Nix. Upgrades preserve the plugin's existing `config.json` and archive
the replaced plugin, loader binary, and service (when changed) under
`~/homebrew/.trash/decky.*`. Other plugins are left alone.

Use repository changes to update the pinned versions and hashes. Applying this
configuration restores the pinned loader and replaces a plugin whose version
metadata differs; avoid using the built-in updaters for these two components.
Reapplying unchanged files does not restart Decky. If SteamOS removes the service
or Steam's debugging flag, reapply the Home Manager configuration.

### Recovery

Check `systemctl status plugin_loader.service` and
`journalctl -u plugin_loader.service` for loader failures. Runtime compatibility
with Steam updates must be checked on the Deck.

To roll back to a prior Nix-managed version, revert the version/hash change and
reapply. To recover a pre-existing manual installation, stop
`plugin_loader.service`, restore its archived files with sudo, and start it again.
Move the current plugin into another backup directory first; do not discard its
state. Reapplying this configuration will enforce its pins again.
