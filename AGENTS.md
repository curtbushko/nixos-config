# Repository Instructions

## Project Shape

This is a personal Nix flake managed with Snowfall Lib. Keep changes aligned with the existing Snowfall layout instead of adding custom loader code or ad hoc module discovery.

- `flake.nix` is the entry point and calls `inputs.snowfall-lib.mkLib` / `lib.mkFlake`.
- `systems/<system>/<host>/default.nix` contains per-machine system configuration.
- `homes/<system>/<user>@<host>/default.nix` contains per-user Home Manager configuration.
- `modules/nixos/**` contains NixOS-only modules.
- `modules/darwin/**` contains nix-darwin-only modules.
- `modules/home/**` contains shared Home Manager modules and most user packages.
- `modules/home/scripts/` contains shell scripts packaged via `pkgs.writeScriptBin` from `modules/home/scripts/default.nix`.
- `modules/home/llm/codex/**` manages the generated global Codex configuration under `~/.config/codex`.
- `secrets/**` is managed through sops-nix. Do not print, decrypt, rewrite, or move secrets unless explicitly asked.

The intended layering is:

- Linux: `flake.nix` -> `systems/` -> `modules/nixos/` -> `modules/home/`
- macOS: `flake.nix` -> `systems/` -> `modules/darwin/` -> `modules/home/`

## Skills And Startup

Before code changes, check available skills under `~/.config/codex/skills/` and read the relevant language/framework skill files completely. For this repository, the Nix skill usually applies; the Bash skill applies when editing scripts under `modules/home/scripts/` or hook/check scripts.

Follow TDD for implementation changes. For Nix/config changes, create or identify the smallest validation that proves the change before implementation, then run the relevant build/check after implementation.

## Nix Style

- Prefer the repository's existing Nix style over generic examples.
- Format with `make fmt` when possible. The Makefile uses `alejandra --quiet .`.
- Keep flake inputs pinned in `flake.lock`; use `inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"` unless the existing input intentionally keeps its own nixpkgs, as `neovim` does.
- Use the existing `curtbushko.*` option namespace for custom modules.
- Modules generally use:
  - argument set at top: `{ config, lib, pkgs, inputs, ... }:`
  - `let inherit (lib) types mkOption mkIf; cfg = config.curtbushko.<path>; in`
  - `options.curtbushko.<path>.enable` with default `false`
  - `config = mkIf cfg.enable { ... };`
- Host and home files enable features through `curtbushko = { ... };` rather than importing feature internals directly.
- Put shared user tools in `modules/home/**`; put Linux-only services/hardware/window-manager config in `modules/nixos/**`; put macOS system defaults, Homebrew, and nix-darwin behavior in `modules/darwin/**` or `systems/aarch64-darwin/**`.
- Use `lib.optionals pkgs.stdenv.isLinux` or equivalent platform checks for cross-platform Home Manager modules.
- Keep comments short and practical, especially around pins, workarounds, or impure behavior.

## Scripts

Shell scripts are first-class configuration here and are packaged from Nix.

- New scripts go in `modules/home/scripts/` and must be added to `modules/home/scripts/default.nix`.
- Use Bash for automation; do not add Python scripting.
- Use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Quote variables and prefer arrays for lists.
- Check external commands with `command -v` when scripts depend on optional tools.
- Do not use emojis in scripts or CLI output; use Nerd Font symbols only when the surrounding code already expects them.
- Validate script edits with `shellcheck` and `shfmt` when available.

## Common Commands

- Enter the dev environment: `nix develop`
- Format Nix: `make fmt`
- Build/switch current host: `make switch`
- Test current host: `make test`
- Dry-build NixOS current host: `make dry-build`
- Update all flake inputs managed by this repo: `make update-all`
- Update one input: `nix flake update <input>`
- Show Makefile targets: `make help`

Host routing in the Makefile is based on `hostname -s`:

- Darwin hosts: `curtbushko-X3FR7279D2`, `m4-pro`, `m1-air`
- NixOS hosts: `gamingrig`, `node00`, `node01`, `node02`
- Home Manager-only host: `steamdeck`

Many build and switch commands use `--impure` because some modules read user-local state such as Flair theme files. Preserve that behavior unless replacing the underlying impure dependency.

## Validation

Use the narrowest meaningful validation first, then broaden before finishing.

- Nix syntax/format: `make fmt`
- Flake evaluation: `nix flake check`
- Current host build/test: `make test`
- NixOS dry run: `make dry-build`
- Darwin build/test: `make test` on a Darwin host
- Home Manager build: `make test` on Home Manager-only hosts

If a command cannot run in the current environment because it needs sudo, a specific host, a remote builder, unavailable cache access, or secrets, state that clearly and run the closest non-destructive check available.

## File Handling

- Never use `rm`; move files into `.trash/` instead.
- `.trash/` is already ignored. If needed, create it with `mkdir -p .trash`.
- Do not add git submodules.
- Do not create `.gitkeep` files.
- Do not rewrite unrelated user changes in a dirty worktree.
- Use single quotes for git commit messages if committing, and do not mention Codex in commit messages.

## Secrets And Impure Files

- sops files live under `secrets/` and are consumed by modules such as `modules/nixos/services/k8s/**` and `modules/home/secrets/default.nix`.
- Do not expose decrypted values in logs, commits, comments, or examples.
- Existing modules may read files from the user's home directory with `builtins.pathExists` and `builtins.readFile`; keep fallback values when adding similar behavior so evaluation can still proceed without local files.
