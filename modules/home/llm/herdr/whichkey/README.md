# herdr whichkey

Local herdr popup plugin that shows a hardcoded key -> command menu.

## First-time setup

The Go module needs a `go.sum` and Nix needs a real `vendorHash`. On first
build:

1. In this directory, run `go mod tidy` to generate `go.sum`.
2. Run `task test` (or `task switch`). The Nix build will fail with a
   `hash mismatch` message showing the correct `sha256-...` value.
3. Paste that value into `whichkeyVendorHash` in `../default.nix`.
4. Run `task switch` again.

## Bind a key

Add to `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "ctrl+space"
type = "plugin_action"
command = "whichkey.open"
description = "which-key menu"
```

Then `herdr server reload-config`.

## Edit the menu

The deployed menu lives at `~/.config/herdr/plugins/config/whichkey/menu.toml`
(managed by home-manager from `menu.toml` in this directory).

## Move panes

Open which-key, then press `m`:

- `h` / `j` / `k` / `l`: swap the caller pane left / down / up / right.
- `n`: move the caller pane into a new tab and follow it.
- `w`: move the caller pane into a new workspace and follow it.

Directional swaps need an adjacent pane in that direction.

## Collapse the workspace sidebar

Press `Ctrl+B`, then `B` to collapse or expand the workspace sidebar.
Herdr 0.9.1 exposes this as a client keybinding (`toggle_sidebar`), not a
CLI/socket API action, so it cannot currently be dispatched from this menu.
`pane send-keys` sends input to the process inside a pane, not to Herdr's UI.
