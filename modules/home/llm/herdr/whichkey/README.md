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
