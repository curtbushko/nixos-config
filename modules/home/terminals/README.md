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
with `--extra-listen 0.0.0.0:7297 --allow-anonymous`. This is enabled for
`curtbushko-K4W6XK6XND` only. The local Unix socket remains available to the app
and CLI. The module disables built-in Tailscale and the app's automatic server
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

## HerdR keyboard bindings

`rex/init.lua` matches the explicit bindings in `modules/home/llm/herdr/default.nix`.
Home Manager reloads the config after linking files and installing the theme,
provided Rex's CLI and an existing server are available. It does not start Rex.
Use `rex config check` to validate, or `rex config reload` for a manual reload.
Rex does not watch configuration changes. Shortcuts set through Rex's UI override
these file-based bindings; clear any conflicting UI shortcuts.

| Keys | Action |
| --- | --- |
| Ctrl+B, V / Alt+N | Split right |
| Ctrl+B, - / Alt+M | Split down |
| Ctrl+B, H/J/K/L / Alt+arrows | Focus pane spatially |
| Alt+J / Alt+K | Focus down / up |
| Alt+H / Alt+L | Previous / next pane in column order, then adjacent tab |
| Alt+[ / Alt+] | Previous / next tab |
| Alt+= / Alt+- | Resize up / down |
| Ctrl+B, Z / Alt+P | Zoom pane |
| Ctrl+B, 1–9 / Alt+1–9 | Go to tab 1–9 |
| Ctrl+B, Space / Alt+Space | Floating which-key menu |
| Ctrl+B, E | Rex sidebar (not HerdR's Neovim plugin) |
| Ctrl+B, Ctrl+B | Send Ctrl+B to the terminal |

Alt+H/L sorts panes by their x/y positions, including vertically stacked panes,
just like `herdr-smart-focus`. Crossing a tab boundary wraps within the current
Rex session and focuses the first/last pane in the destination tab. The action
also explicitly selects the destination client tab; server-side focus alone
does not update the visible app tab.
HerdR's detach (Ctrl+B, D) and agent-output file picker (Ctrl+B, O) have no
matching Rex client action and are left unmapped. Rex's other default shortcuts
remain available.

## Which-key popup

[rex-whichkey](https://github.com/curtbushko/rex-whichkey) is a separate plugin,
consumed through the pinned `rex-whichkey` flake input. The input uses Git over
SSH while the repository is private; fetching it requires GitHub SSH access.
`rex.nix` calls the input's `lib.mkPackage`, supplies the installed Rex CLI path,
and inserts the packaged Lua entry point into `rex/init.lua`.

`init.lua` configures it with `whichkey.setup({ position = "center" })`.
The implementation, helper, dependencies, tests, and upstream attribution now
live in the plugin repository, not in this configuration. Update it with
`nix flake update rex-whichkey`.
The popup reads its inherited terminal theme before painting: OSC 10/11 supply
foreground/background, with a raised popup surface derived from a 12% foreground
blend; OSC 4 supplies yellow keys (3), gray borders/help (8),
red close/confirmation items (1), and cyan-slot submenus (6). It does not override
the terminal theme or change normal panes. Popup placements draw a terminal-cell
box; full-width bars do not. Plugin-owned colors remain fallbacks for missing or
unsupported replies.

Bold key hints, palette-colored section labels, Nerd Font icons, and `»` breadcrumbs
are inspired by the Neovim configuration. Semantic colors are adjusted when
needed for readable contrast. Close actions require explicit confirmation.

Choose `position` in the plugin setup in `rex/init.lua`: `top` and `bottom` are
full-width bars; `left`, `right`, and `center` are framed popup boxes. Center is
the default. Shared Lua area functions handle placement, width, margins, and
content-driven height; **Tab** pages larger menus. Submenu changes and terminal
resizes recalculate the layout. See the [position options](https://github.com/curtbushko/rex-whichkey#position-and-navigation).

The default `overlay` backend works around Rex's current offset clipping by
using a full-window layer and painting only the selected region. Unpainted
cells currently show the underlying pane, but the entire layer stays modal.
Position is the only user-configurable placement setting. Backend, sizing, and spacing are
internal to `areas.lua`. A future Rex fix can switch the internal backend to
normal popup bounds without changing user configuration; that path still needs
visual verification on the fixed app.
Theme queries have a short total timeout, preserve typeahead, and restore terminal
input settings. Piped output and `NO_COLOR` skip queries. Opening does not
reselect the tab afterward, which can replace the client's floating-layer focus.
The helper redraws on resize. The module configures JetBrainsMono Nerd Font for
Rex's terminals. The helper supports
`REX_WHICHKEY_ASCII=1` for plain separators/text icons and `NO_COLOR=1` for uncolored
output; these must be in the Rex server's environment to affect spawned menus.
Explicit terminal cell colors keep the menu visible even when the client overrides
terminal defaults.
The terminal closes on completion, and cancellation restores the original pane's
focus. Selected commands explicitly target the originating client/session/pane,
not the menu's terminal.

Customize keys, groups, icons, action arguments, and confirmation by adding
`spec = { ... }` to the plugin setup in [`rex/init.lua`](rex/init.lua). Omitting
`spec` keeps the default menus. The Rex-side spec supplies a data-only JSON
snapshot to the frontend; callbacks and action arguments remain in Rex. See the
[configuration examples](https://github.com/curtbushko/rex-whichkey#configure-menus). Nested tables
inherit attributes, while full key sequences determine arbitrary submenu depth.
Apply the configuration after editing the spec; activation reloads a running Rex server.

Open it with **Ctrl+B, Space** or **Alt+Space**, then press a displayed key:

- **w**: Rex session operations (the nearest equivalent to HerdR workspaces).
- **t**: New/previous/next/rename/close tabs, or **1–9** to select a tab.
- **v / s / z**: Split right / split down / zoom.
- **f**: Focus a pane with **h/j/k/l**.
- **e / c**: Sidebar / native command palette.
- **x**: Close the originating pane.

**Esc/Backspace** returns to the parent menu; **q** exits. Close operations
require a second **y** confirmation. HerdR-specific worktree and swap actions
are omitted rather than mapped to unrelated Rex actions. Moving a pane between
sessions is also omitted: Rex's move API only operates within one session.
Remote Control must remain enabled for menu dispatch. Activation reloads a
running server automatically; otherwise Rex loads the config on its next start.

## Validation

From the root of this repo, test host bindings against the pinned plugin:

```console
plugin_source="$(nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).inputs.rex-whichkey.outPath')"
REX_WHICHKEY_LUA_DIR="$plugin_source/lua/whichkey" nix develop "path:$plugin_source" -c lua modules/home/terminals/tests/rex_keys.lua
bash modules/home/scripts/tests/rex-theme-install_test.sh
rex config check ~/.config/rex/init.lua
```

The plugin's own tests run during its package build. See its
[development instructions](https://github.com/curtbushko/rex-whichkey#development)
for formatting, Luacheck, compatibility, and integration checks. The final
`rex config check` above checks the deployed configuration without reloading it.
