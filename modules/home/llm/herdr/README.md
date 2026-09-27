# HerdR + Pi development environment

> Skills define roles and reasoning. Workflows define contracts and quality gates.
> Routines define when trusted processes run. HerdR owns sessions and execution
> surfaces. Pi is the default AI frontend and adaptive orchestrator.

## Architecture and ownership

Nix installs HerdR, Pi, pi-herdr, herdr-workflows, and herdr-routines. It also
manages stable configuration, global workflows, disabled routine infrastructure,
and the shared skill link. Provider credentials, login state, conversations,
HerdR sessions, plugin databases, worktrees, repositories, and transcripts remain
machine-local.

Pi reads `~/.pi/agent/skills`, Claude reads `~/.claude/skills`, and Codex reads
`~/.codex/skills`. All three are Home Manager links to the same canonical
`modules/home/llm/skills` source. Do not copy those skills into a Pi-specific tree.

HerdR is the persistent terminal/session surface. Pi is the default interactive
agent. The pinned pi-herdr extension delegates Pi, Claude, Codex, and other
supported workers into visible HerdR panes. HerdR Workflows owns deterministic
process sequencing; pi-herdr does not duplicate that workflow logic.

## Pinned versions

| Component | Pin |
| --- | --- |
| HerdR | `v0.9.1` flake |
| Pi | `pi.nix` revision `3f392b014764faf4f0aaa611b6c5d082175ad81c` |
| pi-herdr | npm `0.5.0` tarball with a fixed hash |
| herdr-workflows | `v0.15.1` source plus matching release binary and hash |
| herdr-routines | revision `cd504512d2f1976d39668fbdc0fe9b86cf3eff85` |

Nix owns upgrades. Do not run `herdr update` or `hwf update`. To upgrade, change
the explicit version/revision and fixed hashes, run `nix flake lock` for only the
changed input, validate, rebuild, and commit `flake.nix` with `flake.lock`.

## Install and start

Validate without activation:

```bash
task agent-verify-fast
task agent-verify-full
```

Apply the configuration only when intended:

```bash
task switch
```

Open a new interactive shell so it has the normal Nix profile `PATH`, then check:

```bash
herdr --version
pi --version
hwf --version
herdr integration status
herdr plugin list
```

Start HerdR from that shell with `herdr`. This ensures panes inherit Pi, Claude,
Codex, Copilot, Git, shells, and development tools from the interactive Nix PATH.
Do not start HerdR as a minimal launchd service.

Inside HerdR, start `pi` in a repository. pi-herdr is discovered from the
Nix-managed extension directory. Ask Pi to delegate focused work with the desired
harness, skill, working directory, and isolation requirement. Workers are separate
processes and remain visible and inspectable in HerdR. Use HerdR worktrees for
isolated changes when appropriate.

## Integrations

Home Manager runs the pinned HerdR integration installer in an isolated staging
home, then installs its versioned hook assets. Harness hook configuration remains
declarative. This avoids asking the installer to edit Home Manager symlinks while
still using the official integration generator. The configured integrations are
Pi, Claude Code, Codex, and GitHub Copilot CLI.

After a rebuild, use `herdr integration status`. Authentication is deliberately
not managed here; log into each CLI normally on each machine.

## Quality workflows

Global workflows live at `~/.hwf/workflows`:

- `preflight` records Git state and permits dirty worktrees.
- `verify-fast` calls the repository's cheap deterministic gate.
- `verify-full` calls the repository's complete deterministic gate.
- `review` starts a fresh Codex reviewer with the goal, Git state, diff, and
  verification evidence. It succeeds only with an `APPROVED` verdict.
- `implement-review` composes preflight, Pi implementation, fast verification,
  independent review, and full verification. Any failed child gate fails the run.

Run them with `hwf run <name>`. Validate a file with:

```bash
hwf workflow validate ~/.hwf/workflows/implement-review.yaml
```

Repository-local workflows belong in `.hwf/workflows/`. Global workflows do not
create that directory and do not hardcode language commands.

### Repository quality contract

The `agent-quality` dispatcher looks for these targets in `Taskfile.yml`, a
`Makefile`, or a `justfile`:

```text
agent-preflight
agent-verify-fast
agent-verify-full
```

Preflight always prints `git status --short` and runs the optional repository
target. Fast and full verification fail clearly when their required target is
absent. This repository implements the contract in `Taskfile.yml`. Other
repositories can adopt it independently; this setup does not modify them.

## Routines

herdr-routines is linked and receives a valid, disabled smoke-test routine. No
recurring AI work is enabled. Check infrastructure after HerdR is running:

```bash
herdr plugin action invoke herdr-routines.validate
herdr plugin action invoke herdr-routines.status
```

Enable a routine only after its referenced workflow has proven reliable through
interactive runs. Prefer routines that invoke trusted workflows rather than
duplicating their commands.

## Acceptance checks requiring an attached session

The following are intentionally live checks after `task switch`; they create
panes, agent sessions, or worktrees and therefore are not run during a Nix build:

1. Start Pi, Claude, Codex, and Copilot in HerdR and confirm agent recognition.
2. From Pi, delegate one Pi, one Codex, and one Claude worker; run two concurrently,
   collect their results, and inspect their panes.
3. Repeat one delegation in a HerdR-created worktree.
4. Run a canonical top-level shared skill that selects multiple focused skills.
5. Run `implement-review` successfully, then deliberately fail a repository
   quality target and confirm the workflow exits nonzero.
6. Validate routines and manually invoke only the disabled smoke infrastructure.

Tmux remains installed as a fallback. Neovim, remote access, web frontends, and
session synchronization are outside this module.
