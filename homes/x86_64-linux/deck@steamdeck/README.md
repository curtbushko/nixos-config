# Steam Deck

This is a standalone Home Manager configuration on SteamOS, not NixOS.
System changes during activation require `deck` to have working sudo access.

## Rex

The Linux Rex CLI/server package and shared `init.lua`/which-key configuration
are installed for `deck`. A user service starts Rex with KDE's
`plasma-workspace.target` in Desktop Mode and stops it when that target stops.
It is not enabled for Gaming Mode's default user target; a KDE environment
condition also guards startup. Log out and re-enter Desktop Mode after applying,
then check `systemctl --user status rex-server.service`.

Rex keeps its private local Unix socket and also listens on the Deck's Tailscale
IPv4 address at port 7297, discovered at service startup. Its `tailnet://` listener
uses the existing host tailscaled to identify callers and admits only the node's
owning Tailscale account by default, subject to tailnet access rules. It does not
allow anonymous connections, bind a LAN/wildcard address, or enroll a separate
Tailscale node. Tagged nodes need a separate access-policy choice.

From another device on the same tailnet, use `rex -S steamdeck:7297 ls` (substitute
the Deck's actual MagicDNS name if different). Tailscale must already be logged
in. The user service retries failed startup every five seconds while Desktop Mode
is active. The listener stops with the desktop session; it is not intended to be
available in Gaming Mode.

This does not install the macOS GUI, login server, or system service. The package
uses the same `patchelf` workaround and executable smoke test as Gamingrig.

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
