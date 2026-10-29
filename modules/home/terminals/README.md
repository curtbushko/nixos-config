# Rex

`ns.terminals.enable` enables the Rex theme and keyboard module on macOS. Disable it with
`ns.terminals.rex.enable = false;` if Rex is not used.

Rex is currently an invite-only macOS application, installed separately from Nix.
See the [installation documentation](https://www.superlogical.com/rex/docs/installation).
The module does not install the app. It manages `~/.config/rex/init.lua`;
back up any existing file before activation (Home Manager will not force-overwrite it).

## Font

Home Manager sets Rex's terminal font to **JetBrainsMono Nerd Font**, **Medium**,
**10 pt**, matching Ghostty. Reopen Rex after activation if it is already running.

## Ghostty theme

Home Manager activation copies a **regular file** to `$XDG_CONFIG_HOME/rex/themes/flair`
(normally `~/.config/rex/themes/flair`); Rex's importer rejects store symlinks.
Replaced files/links are preserved in `rex/themes/.trash/`, and unchanged files
are left alone. Its colors are extracted directly from the
managed Ghostty configuration, including the custom Stylix palette and Ghostty's
`base01` background. There is no separately maintained color mapping.

After applying the Home Manager configuration:

1. In Rex's theme settings, choose **Import Theme File**.
2. Import `~/.config/rex/themes/flair` (adjust for a custom XDG config directory).
3. Select the imported **flair** theme for the appearance you use (light and/or dark).

To select an already-imported theme from the CLI:

```console
rex -C m4-pro do client.theme.change name=flair
```

Use your client's label from `rex client ls` instead of `m4-pro`, or omit `-C`
when exactly one app client is connected. The module enables **Remote Control**
under **Rex Settings → Rex Server** using the `rex.client.remoteControl` macOS
preference. This permits CLI-driven client actions; it is not macOS screen sharing.
If Rex was already running during activation, reopen the app if it has not picked
up the preference. The command above selects the theme;
it does not import the file. Rex currently exposes no theme-import action.

Rex imports a snapshot, rather than watching the file. Reimport after changing
your Stylix theme. Theme selection is a client preference; the documented
`init.lua` API does not expose startup theme selection. This module therefore
avoids overwriting undocumented theme records. Once the theme is
successfully imported, its `Workspace.customThemes` record and theme ID can be
inspected before adding declarative preference management.

Inside Rex terminals, its CLI is already on `PATH`. For other terminals, the
module links `~/.local/bin/rex` to the app's bundled CLI and adds `~/.local/bin`
to `home.sessionPath`. Open a new shell after activation to pick up the PATH.
The link stays pointed at the installed app across app updates.

The default bundle is `/Applications/Rex Beta.app`. If it is installed elsewhere,
set `ns.terminals.rex.appPath` to its bundle path (for example `/Applications/Rex.app`).
Check the Lua configuration with `rex config check`; reload it with `rex config reload`.

## Remote access over the LAN

Set `ns.terminals.rex.lan.enable = true;` to run Rex under a user launchd agent
with `--extra-listen 0.0.0.0:7297 --allow-anonymous`. It is disabled on the
work Mac (`curtbushko-K4W6XK6XND`), which must remain local-only. Enabling
LAN access on m4-pro is a separate macOS setup step. The local Unix socket
remains available to the app and CLI. The module disables built-in Tailscale and the app's automatic server
restart so launchd can own the server and preserve its listener flags.

**Every connection has full access as your user, with no authentication or
encryption.** The default listens on every IPv4 interface, not just Wi-Fi or
Ethernet. Use only on trusted networks, do not port-forward it, and restrict
access with your firewall. Set `ns.terminals.rex.lan.listenAddress` to a specific
LAN IP and port if it must not listen on other interfaces. Allow incoming Rex
connections in the macOS firewall if prompted.

Initial setup requires a server restart. Finish your Rex sessions first:
`rex server stop` ends every program in them. Quit the Rex app, stop its server,
then apply the Home Manager configuration and reopen Rex. The launchd agent
starts the server at login and restarts it on exit. It cannot replace an already
running server that owns the same socket; Lua config reload alone does not
change listeners.

From another LAN device, use **Add Remote Host…** with `http://<LAN-IP>:7297`,
or run `rex -S http://<LAN-IP>:7297 ls`. Confirm it from that other device;
local status alone does not verify routing or firewall access.

## Gamingrig Linux server

Gamingrig enables `ns.services.rex.enable`, importing the pinned upstream Rex
NixOS login-server module. It starts sessions as `curtbushko`, shared with that
user's local Rex server on systemd-logind hosts. Run `rex ls` locally; the
login server itself has a root-only coordination socket.

- **m4-pro over Tailscale:** use **Add Remote Host…** with
  `https://curtbushko@gamingrig.<tailnet>.ts.net`. HTTPS must be enabled on the
  tailnet, and gamingrig must already be signed in. The Tailscale identity in
  SOPS's `TS_USER` entry is mapped to the account.
- **Work over LAN:** use `http://curtbushko@192.168.2.55:7297`. This listener is
  anonymous and unencrypted. Every permitted LAN device can run commands as
  `curtbushko`; it is not a password-authenticated login. Do not port-forward it.
- **Gamingrig to work:** intentionally not configured; work exposes no server.

Reserve `192.168.2.55` for gamingrig in DHCP. The listener binds that address;
`ns.services.rex.lanAddress` can override it. A dedicated nftables table allows
TCP 7297 only from `192.168.2.0/24` on `eno1` (and local loopback), dropping other
sources including IPv6. It loads before Rex, without enabling the general NixOS
firewall or flushing Docker's tables. The restriction remains on service stop;
if retiring Rex, remove it explicitly with `sudo nft delete table inet rex`.

SOPS decrypts the dotenv file to a root-only runtime file. **sops-nix does not
select individual keys from dotenv files.** `rex-auth.service` uses the tested
`rex-env-render` helper to parse only `export TS_USER` and
`export REX_PACKAGE_TOKEN`, without evaluating shell code or logging values.
It validates the selected values before generating a root-only accounts JSON
and a mode-0600 netrc owned by `curtbushko` under `/run/rex-auth`. Rex depends
on successful preparation. Invalid input produces a generic error rather than
passing the raw dotenv file to Rex. Secret updates restart preparation and Rex.
Neither identity nor token is embedded in the Nix store.

This uses the existing age key at
`/home/curtbushko/.config/sops/age/keys.txt`, accessible to root during activation.
Set `TS_USER` to the exact Tailscale login (including `@github` for GitHub
accounts), without a `tailscale:` prefix. Nix uses `/run/rex-auth/netrc` on
gamingrig; an environment export is not needed. Darwin builds use the separately
installed macOS app and do not fetch the private Rex package input or need its
token. Only the Linux module is exposed to Snowfall, avoiding eager input-library
discovery. Initial Linux bootstrap or updating the Rex input on another machine
needs its own private netrc; pass its path with
`nix flake update rex --option netrc-file /path/to/private/netrc`.

After activation, check `systemctl status rex-auth rex-firewall rex-login-server
rex-tailscale-serve` and `tailscale serve status`. Verify each remote path from
the corresponding Mac; successful local evaluation does not prove connectivity.

## Application keyboard bindings

Cmd/Super controls application content. Option/Alt controls desktop focus;
Option+Ctrl moves and sizes desktop windows in Niri and OmniWM. Cmd+Option
moves and sizes Rex panes.
Home Manager reloads the config after linking files and installing the theme,
provided Rex's CLI and an existing server are available. It does not start Rex.
Use `rex config check` to validate, or `rex config reload` for a manual reload.
Rex does not watch configuration changes. Shortcuts set through Rex's UI override
these file-based bindings; clear any conflicting UI shortcuts.

| Keys | Action |
| --- | --- |
| Cmd+D / Cmd+Shift+D | Split right / down |
| Cmd+J/K / Cmd+Down/Up | Focus pane down / up |
| Cmd+H/L / Cmd+Left/Right | Previous / next pane, then tab, then connected session |
| Cmd+T | New tab |
| Cmd+W | Close tab |
| Cmd+1–9 | Go to tab 1–9 |
| Cmd+E | Rex sidebar |
| Cmd+Option+H/J/K/L | Move pane left/down/up/right |
| Cmd+Option+- / Cmd+Option+= | Shrink / grow pane width by 10 percentage points |
| Cmd+Option+W | Cycle pane widths: 1/3, 1/2, 2/3 of the window |

Cmd+H/L sorts panes by x/y position, then crosses tabs and sessions. Sessions
are ordered by the home server first, then hosts in `rex.servers()` order, with
each server's sessions in server order. Navigation wraps and skips sessions
without tabs. J/K stays spatial within the current tab.

Each keypress launches `rex/cycle.lua` asynchronously. Before attaching or changing
focus, it verifies that the source still exists in its server's live session list
and is attached to a connected app client. Remote sessions are eligible only when
that same app has a connected client on the remote server. App matching requires
a unique nonempty client label, name, and platform; use the same label, such as
`m4-pro`, on the app's local and remote connections. Lost connections and failed
hosts are excluded from the navigation list, which is rebuilt for each step.

The helper rechecks the source and destination immediately before changing focus.
A missing source, stale pane, or disconnected source connection results in no
navigation, not a fallback to another host. Tab/session activation is routed through
the destination server's app client. A pane move within the current tab does not
reactivate that tab. The CLI uses a one-second request timeout and a five-second
process budget. The app does not wait for the helper; additional cycling keys are
ignored while a step is running so they cannot build up stale session switches.
The Mac's Remote Control setting must remain enabled for tab/session activation.
These guards are covered by offline tests; a real disconnect/crash reproduction
has not been run against the updated code.

Width changes adjust the nearest horizontal split. A single pane is unchanged;
unreachable presets inside nested splits are skipped. Incremental changes are
clamped to leave both sides of the split visible. Ctrl+B is no longer a prefix,
and there is no direct zoom binding. Native Cmd+Q remains application Quit.
The macOS Hide Rex menu shortcut moves to Ctrl+Shift+Cmd+H so Cmd+H reaches
navigation. Restart Rex after changing native menu shortcuts. Cmd+Space is
currently unbound while the replacement menu is developed.

Ghostty uses the same Cmd/Super tab and split keys, plus its own command menu. H/L selects
tabs and J/K focuses vertical splits; it does not implement Rex's combined
pane/tab/session traversal. Cmd+Option+H/L reorders tabs. Ghostty's resize keys move a
divider by 10 cells, not 10%, and it has no equivalent pane-width preset action
or directional pane-move action. Those capabilities are not emulated.

Firefox and other applications are not automatically remapped by these terminal
settings. Firefox's reserved chrome shortcuts require an additional remapping
mechanism; ordinary Home Manager preferences or Vimium page bindings alone do
not establish the same Cmd+H/J/K/L behavior everywhere.

## Validation

From the root of this repo, test the built-in bindings and navigation without
an external menu plugin:

```console
nix shell --inputs-from . nixpkgs#lua5_4 -c lua modules/home/terminals/tests/rex_keys.lua
nix shell --inputs-from . nixpkgs#lua5_4 -c lua modules/home/terminals/tests/rex_cycle.lua
bash modules/home/scripts/tests/rex-theme-install_test.sh
nix-instantiate --eval --strict modules/home/terminals/tests/rex-cli.nix
nix-instantiate --eval --strict modules/nixos/services/rex/tests/config.nix
rex config check modules/home/terminals/rex/init.lua
```

The final command validates the source configuration without activating it or
reloading the running server. After applying the configuration, Home Manager
removes the former managed menu files and reloads an existing Darwin server.
