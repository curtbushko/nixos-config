# Repository Instructions

## What This Repo Is

This is Curt's personal Nix flake for NixOS, nix-darwin, and Home Manager. It is built with Snowfall Lib, so prefer Snowfall's directory conventions and automatic module discovery over custom import machinery.

The flake namespace is `ns`.

- `flake.nix` defines inputs, the Snowfall lib, shared flake settings, overlays, system modules, and dev shells.
- `Taskfile.yml` is the real command surface. Inside `nix develop`, `make` is a wrapper around `task`.
- `systems/<system>/<host>/default.nix` contains per-host NixOS or nix-darwin config.
- `homes/<system>/<user>@<host>/default.nix` contains per-user Home Manager config.
- `modules/nixos/**` contains NixOS-only modules.
- `modules/darwin/**` contains nix-darwin-only modules.
- `modules/home/**` contains shared Home Manager modules and most packages.
- `modules/home/scripts/` contains Bash scripts packaged from `modules/home/scripts/default.nix` with `pkgs.writeScriptBin`.
- `modules/home/llm/codex/**` is the source that Home Manager deploys into `~/.codex`.
- `packages/**` contains custom packages.
- `secrets/**` is managed by sops-nix. Do not print, decrypt, rewrite, or move secrets unless explicitly asked.

Layering:

- Linux: `flake.nix` -> `systems/x86_64-linux/<host>` -> `modules/nixos` -> `modules/home`
- macOS: `flake.nix` -> `systems/aarch64-darwin/<host>` -> `modules/darwin` -> `modules/home`
- Home-only hosts: `flake.nix` -> `homes/<system>/<user>@<host>` -> `modules/home`

## Before Changing Files

Follow the global Codex instructions deployed from `modules/home/llm/codex/AGENTS.md`: list available skills, read the applicable skill files completely, and state the relevant skill acknowledgement before implementation.

For this repo, the Nix skill usually applies. The Bash skill applies when editing files under `modules/home/scripts/`, shell snippets in Nix modules, hook/check scripts, or `Taskfile.yml` command blocks.

Use TDD where there is executable behavior. For Nix/config changes, identify the smallest evaluation/build/format check that would prove the change, make the change, then run that check and the relevant broader validation if practical.

Check `git status --short` before edits. The worktree may be dirty; do not revert or rewrite changes you did not make.

## Commands

Prefer running commands through the task file when possible:

- Enter dev environment: `nix develop`
- List tasks: `task -l`
- Format Nix: `task fmt`
- Test current host: `task test`
- Switch current host, only when explicitly requested by the user: `task switch`
- NixOS dry build: `task dry-build`
- Update all managed inputs: `task update-all`
- Update one input: `nix flake update <input>`
- Repair store: `task repair`

Host routing in `Taskfile.yml` is based on `hostname -s`:

- Darwin: `curtbushko-K4W6XK6XND`, `m1-pro`, `m4-pro`
- NixOS: `gamingrig`, `node00`, `node01`, `node02`
- Home Manager only: `steamdeck`

Many build/test/switch tasks use `--impure` because modules read user-local files such as Flair themes. Preserve that behavior unless replacing the underlying impure dependency.

Do not run `task switch` unless the user explicitly asks for it. Future Codex sessions usually will not have the permissions or sudo credentials needed to activate the NixOS, nix-darwin, or Home Manager configuration. Validation commands such as `task test`, `task dry-build`, `nix flake check`, and `task fmt` are still appropriate when relevant.

Note: `Taskfile.yml` currently contains an existing `rm -f` cleanup in the Home Manager switch path. Do not copy that pattern into new work; follow the file handling rules below.

## Nix Style

Use the existing `ns.*` option namespace.

Typical module pattern:

```nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.<path>;
in {
  options.ns.<path>.enable = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Whether to enable <feature>
    '';
  };

  config = mkIf cfg.enable {
    # ...
  };
}
```

Guidelines:

- Prefer established module patterns in nearby files over generic examples.
- Enable features from host/home files with `ns = { ... };`.
- Put shared user packages and dotfiles in `modules/home/**`.
- Put Linux services, hardware, and display stack config in `modules/nixos/**`.
- Put macOS defaults, Homebrew, nix-darwin behavior, and Darwin-specific services in `modules/darwin/**` or `systems/aarch64-darwin/**`.
- Use `lib.optionals pkgs.stdenv.isLinux` or `lib.optionals pkgs.stdenv.isDarwin` for cross-platform Home Manager modules.
- Prefer explicit `pkgs.foo` references for new code. Some older files still use `with pkgs`; do not expand that style unless you are only making a very small local edit in an existing list.
- Keep flake inputs pinned in `flake.lock`. Add `inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"` unless the input intentionally needs its own nixpkgs. `neovim` is an existing exception.
- Keep comments short and practical, especially around pins, workarounds, host-specific behavior, or impure reads.
- Do not add git submodules.

## Scripts

Scripts are packaged as Nix-managed tools.

- New scripts go in `modules/home/scripts/`.
- Add every new script to `modules/home/scripts/default.nix`.
- Use Bash, not Python, for repository scripting and automation.
- Use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Quote variables, prefer arrays for lists, and check optional external commands with `command -v`.
- Do not use emojis in script output. Nerd Font symbols are acceptable only where the surrounding script already expects them.
- Validate script edits with `shellcheck` and `shfmt` when available.

## Validation

Use the narrowest useful validation first, then broaden before finishing when practical.

- Documentation-only change: inspect the rendered Markdown/source diff; no build is normally needed.
- Nix formatting: `task fmt`
- Flake evaluation: `nix flake check`
- Current-host build/test: `task test`
- NixOS dry run: `task dry-build`
- Darwin build/test: `task test` on a Darwin host
- Home Manager build: `task test` on Home Manager-only hosts

If a command cannot run because it needs sudo, a particular host, a remote builder, cache access, or secrets, say so and run the closest non-destructive check available.

## Secrets And Impure Files

- Do not read decrypted secret values or print secret file contents.
- Do not edit `secrets/**` unless the user explicitly asks.
- Existing modules use `builtins.pathExists` and `builtins.readFile` for user-local files such as Flair theme JSON. Keep fallback values so evaluation still works without those files.
- Avoid exposing host IDs, tokens, keys, or decrypted sops output in logs, examples, or comments.

## File Handling

- Never use `rm`; move files into `.trash/` instead.
- If `.trash/` is needed, create it with `mkdir -p .trash` and ensure `.trash/` is ignored.
- Do not create `.gitkeep` files.
- Do not move, rewrite, or clean generated/task/status files unless necessary for the request.
- Use single quotes for git commit messages if committing, and do not mention Codex or AI tooling in commit messages.

## Practical Change Recipes

Adding a shared package:

1. Find the closest `modules/home/<area>/default.nix` or submodule.
2. Add the package to `home.packages`.
3. Gate platform-specific packages with `lib.optionals`.
4. Run `task fmt`, then `task test` if the current host exercises that module.

Adding a NixOS feature:

1. Add or edit a module under `modules/nixos/**`.
2. Expose options under `options.ns.<area>.<feature>`.
3. Enable it in `systems/x86_64-linux/<host>/default.nix`.
4. Validate with `task fmt` and, on an appropriate NixOS host, `task dry-build` or `task test`.

Adding a Home Manager feature:

1. Add or edit a module under `modules/home/**`.
2. Use `options.ns.<feature>.enable` unless a nearby module has a more specific pattern.
3. Import submodules from the parent `default.nix` when needed.
4. Enable it in `homes/<system>/<user>@<host>/default.nix`.
5. Validate with `task fmt` and `task test` on a host that uses the home config.

Updating Codex behavior:

1. Edit source files under `modules/home/llm/codex/**`, not `~/.codex` directly.
2. Keep root `AGENTS.md` focused on this repo. Keep global Codex behavior in `modules/home/llm/codex/AGENTS.md`.
3. Validate with `task fmt` if Nix changed, and inspect the generated Home Manager file mapping in `modules/home/llm/codex.nix`.
