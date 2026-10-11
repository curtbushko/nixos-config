# HerdR + Pi development environment

> Skills define roles and reasoning. Workflows define contracts and quality gates.
> Routines define when trusted processes run. HerdR owns sessions and execution
> surfaces. Pi is the default AI frontend and adaptive orchestrator.

## Architecture and ownership

Nix installs HerdR, Pi, pi-herdr, herdr-workflows, herdr-routines, and
[herdr-orchestrator](https://github.com/sean1588/herdr-orchestrator). It also
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
| HerdR | `herdr` from the dedicated `herdr-nixpkgs` pin (`0.9.1`) |
| Pi | `pi.nix` revision `3f392b014764faf4f0aaa611b6c5d082175ad81c` |
| pi-herdr | npm `0.5.0` tarball with a fixed hash |
| herdr-workflows | `v0.15.1` source plus matching release binary and hash |
| herdr-orchestrator | `v0.1.0` release binaries with fixed hashes for Linux and macOS |
| herdr-routines | revision `cd504512d2f1976d39668fbdc0fe9b86cf3eff85` |

Nix owns upgrades. Do not run `herdr update` or `hwf update`. To upgrade, change
the relevant input pin and fixed hashes, update only that flake input, validate,
rebuild, and commit `flake.nix` with `flake.lock` when the inputs change.

The orchestrator is installed as `orchestratord`, with HerdR, Git, and the GitHub
CLI on its runtime PATH. It is not a HerdR plugin and is not started automatically.

### Start in the current repository with Codex

With `ns.scripts.enable`, run this inside a HerdR pane:

```bash
cd /path/to/your/github-checkout
codex-orchestrator
```

The wrapper resolves the checkout's `origin` on GitHub and its default branch.
It scaffolds `.orchestrator/pipeline.yaml` and prompts on first use, configures
all roles to launch Codex with workspace-write sandboxing and network access,
and defaults to `dry_run: true` (PRs are not merged automatically). It adds
`.orchestrator/` to the checkout's local Git exclude file, not the shared
`.gitignore`. Existing configuration is preserved; a different repository or
non-Codex role is rejected instead of silently rewritten.

Prerequisites: authenticated `gh` and Codex, plus repository trust already
accepted by opening `codex` in the checkout once. For GitHub authentication:

```bash
gh auth login -h github.com -s repo,workflow
gh auth setup-git
```

The wrapper creates the pipeline's issue label if missing and runs the full
`orchestratord doctor` preflight, including a real Codex smoke-test agent. It
then runs the daemon in the foreground; Ctrl-C stops it. Start only one daemon
per checkout. Label issues `agent-ready` to queue work (or use the label in your
pipeline). The database, task contexts, and event log stay in `.orchestrator/`.
Dry-run tasks stop short of merging and must be merged manually.

The wrapper does not change global Codex trust or permissions, label existing
issues for you, or register an MCP server. For advanced configuration, see the
upstream [Tutorial](https://github.com/sean1588/herdr-orchestrator/blob/v0.1.0/TUTORIAL.md).
Upstream verifies Codex launching but reports end-to-end testing with Claude only.

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
orchestratord version
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
still using the official integration generator. Pi, Claude Code, and Codex are
configured on every LLM-enabled machine. GitHub Copilot CLI is configured only
on the work Mac.

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

1. Start Pi, Claude, and Codex in HerdR and confirm agent recognition. On the
   work Mac, also start Copilot.
2. From Pi, delegate one Pi, one Codex, and one Claude worker; run two concurrently,
   collect their results, and inspect their panes.
3. Repeat one delegation in a HerdR-created worktree.
4. Run a canonical top-level shared skill that selects multiple focused skills.
5. Run `implement-review` successfully, then deliberately fail a repository
   quality target and confirm the workflow exits nonzero.
6. Validate routines and manually invoke only the disabled smoke infrastructure.

Tmux remains installed as a fallback. Neovim, remote access, web frontends, and
session synchronization are outside this module.
