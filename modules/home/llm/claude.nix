{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.llm;

  # Read colors from flair's style.json in ~/.config/flair/
  # Note: Requires --impure flag for nix build/home-manager switch
  flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

  # Default fallback colors if flair style.json doesn't exist
  defaultColors = {
    "statusline-a-bg" = "#1d2021";
    "statusline-a-fg" = "#d4be98";
    "statusline-b-bg" = "#282828";
    "statusline-b-fg" = "#d4be98";
    "statusline-c-bg" = "#3c3836";
    "statusline-c-fg" = "#a9b665";
  };

  colors =
    if builtins.pathExists flairStylePath
    then builtins.fromJSON (builtins.readFile flairStylePath)
    else defaultColors;

  a_bg = colors."statusline-a-bg";
  a_fg = colors."statusline-a-fg";
  b_bg = colors."statusline-b-bg";
  b_fg = colors."statusline-b-fg";
  c_bg = colors."statusline-c-bg";
  c_fg = colors."statusline-c-fg";
in {
  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        includeCoAuthoredBy = false;
        # Remove all MCP servers
        mcp.servers = {};
        hooks = {
          SessionStart = [
            {
              hooks = [
                {
                  type = "command";
                  timeout = 10;
                  command = ''
                    # Inject skill awareness and TDD reminders
                    if [ -x "$HOME/.claude/scripts/session-start.sh" ]; then
                      "$HOME/.claude/scripts/session-start.sh"
                    fi
                  '';
                }
              ];
            }
          ];
          UserPromptSubmit = [
            {
              hooks = [
                {
                  type = "command";
                  command = ''
                    # Remind about checking skills before coding
                    if echo "$PROMPT" | grep -qiE "implement|create|build|write.*code|add.*feature"; then
                      echo "REMINDER: Check ~/.claude/skills/ before coding!"
                    fi
                  '';
                }
              ];
            }
          ];
          PostToolUse = [
            {
              matcher = "Write|Edit";
              hooks = [
                {
                  type = "command";
                  timeout = 10;
                  command = ''
                    # Check for emojis in written/edited files
                    INPUT=$(cat)
                    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
                    if [ -n "$FILE" ] && [ -f "$FILE" ]; then
                      if echo "$FILE" | grep -qE '\.(go|js|ts|jsx|tsx|py|rs|sh|bash|nix)$'; then
                        if grep -P '[\x{1F600}-\x{1F64F}\x{1F300}-\x{1F5FF}\x{1F680}-\x{1F6FF}\x{2600}-\x{26FF}]' "$FILE" 2>/dev/null; then
                          echo "Warning: File contains emojis. Use Nerd Font icons instead." >&2
                        fi
                      fi
                    fi
                    exit 0
                  '';
                }
              ];
            }
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  timeout = 5;
                  command = ''
                    # Validate bash scripts after creation
                    INPUT=$(cat)
                    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
                    # Check if command created a .sh file
                    if echo "$CMD" | grep -qE '>\s*[^|]+\.sh'; then
                      echo "Reminder: New bash script should have shebang and set -euo pipefail" >&2
                    fi
                    exit 0
                  '';
                }
              ];
            }
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  timeout = 5;
                  command = ''
                    INPUT=$(cat)
                    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
                    if echo "$CMD" | grep -q '^git commit'; then
                      MSG=$(git log -1 --pretty=%B 2>/dev/null)
                      if echo "$MSG" | grep -qE '\$\(cat|<<.*EOF|<<.*HEREDOC'; then
                        printf '{"decision":"block","reason":"Commit message contains heredoc junk. Run: git commit --amend -m your-clean-message"}\n'
                        exit 0
                      fi
                    fi
                    exit 0
                  '';
                }
              ];
            }
          ];
          Stop = [
            {
              hooks = [
                {
                  type = "command";
                  timeout = 5;
                  command = ''
                    echo "Reminder: Run ~/.claude/scripts/quality-gates.sh before committing"
                  '';
                }
              ];
            }
          ];
        };
        permissions = {
          defaultMode = "auto";
          allow = [
            # --- Shell basics ---
            "Bash(make:*)"
            "Bash(go:*)"
            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(rg:*)"
            "Bash(grep:*)"
            "Bash(cat:*)"
            "Bash(mkdir:*)"
            "Bash(curl:*)"
            "Bash(echo:*)"
            "Bash(do)"
            "Bash(done)"
            "Bash(env)"
            "Bash(awk:*)"
            "Bash(bash:*)"
            "Bash(touch:*)"
            "Bash(tee:*)"
            "Bash(cp:*)"
            "Bash(tar:*)"
            "Bash(mktemp:*)"
            "Bash(chmod:*)"
            "Bash(unzip:*)"
            "Bash(readlink:*)"
            "Bash(which:*)"
            "Bash(xxd)"
            "Bash(ldd:*)"
            "Bash(tree:*)"
            "Read(~/.claude/**)"

            # --- System / hardware ---
            "Bash(journalctl:*)"
            "Bash(sudo ls:*)"
            "Bash(sudo cat:*)"
            "Bash(sudo systemctl:*)"
            "Bash(sudo tail:*)"
            "Bash(sudo chown:*)"
            "Bash(sudo nixos-rebuild:*)"
            "Bash(systemctl:*)"
            "Bash(systemctl status:*)"
            "Bash(pactl:*)"
            "Bash(strace:*)"
            "Bash(lspci:*)"
            "Bash(ss -tlnp:*)"
            "Bash(netstat:*)"
            "Bash(pi:*)"

            # --- Nix ---
            "Bash(nix search:*)"
            "Bash(nix build:*)"
            "Bash(nix eval:*)"
            "Bash(nix develop:*)"
            "Bash(nix log:*)"
            "Bash(nix flake check:*)"
            "Bash(nix flake show:*)"
            "Bash(nix flake update:*)"
            "Bash(nix flake metadata:*)"
            "Bash(nix-option:*)"
            "Bash(nix-build:*)"
            "Bash(nix-instantiate:*)"
            "Bash(nix-locate:*)"

            # --- Git ---
            "Bash(git add:*)"
            "Bash(git commit:*)"
            "Bash(git diff:*)"
            "Bash(git log:*)"
            "Bash(git push:*)"
            "Bash(git status:*)"
            "Bash(git stash:*)"
            "Bash(git show:*)"
            "Bash(git show-ref:*)"
            "Bash(git checkout:*)"
            "Bash(git symbolic-ref:*)"
            "Bash(git ls-remote:*)"
            "Bash(git tag:*)"
            "Bash(git:*)"

            # --- GitHub CLI ---
            "Bash(gh api:*)"
            "Bash(gh pr view:*)"
            "Bash(gh pr diff:*)"
            "Bash(gh pr checks:*)"
            "Bash(gh issue list:*)"
            "Bash(gh run view:*)"
            "Bash(gh run list:*)"
            "Bash(gh run watch:*)"
            "Bash(gh release create:*)"

            # --- Go tooling ---
            "Bash(golangci-lint run)"
            "Bash(golangci-lint run:*)"
            "Bash(golangci-lint version:*)"
            "Bash(go-arch-lint check)"
            "Bash(go-arch-lint check:*)"
            "Bash(go-ai-lint ./...)"
            "Bash(gofmt:*)"
            "Bash(goimports:*)"
            "Bash(go get:*)"
            "Bash(go mod tidy:*)"
            "Bash(GOPROXY=direct go install:*)"

            # --- Task runner ---
            "Bash(task build:*)"
            "Bash(task test:*)"
            "Bash(task test *)"
            "Bash(task lint:*)"
            "Bash(task lint:arch:*)"
            "Bash(task format *)"
            "Bash(task fmt *)"
            "Bash(task ci *)"

            # --- Node / Bun ---
            "Bash(npm install)"
            "Bash(npm run test:coverage:*)"
            "Bash(bun test:*)"
            "Bash(bun run build:*)"
            "Bash(bunx biome check:*)"

            # --- .NET ---
            "Bash(dotnet build:*)"
            "Bash(dotnet test:*)"
            "Bash(dotnet restore:*)"
            "Bash(dotnet clean:*)"

            # --- Zig ---
            "Bash(zig build:*)"
            "Bash(zig build *)"
            "Bash(zig fmt:*)"
            "Bash(zig fmt *)"

            # --- Containers / K8s ---
            "Bash(docker run:*)"
            "Bash(kubectl config:*)"

            # --- Media ---
            "Bash(ffmpeg:*)"
            "Bash(ffprobe:*)"
            "Bash(blender:*)"
            "Bash(godot:*)"

            # --- Misc tools ---
            "Bash(tailscale status:*)"
            "Bash(vulkaninfo:*)"
            "Bash(packwiz refresh:*)"
            "Bash(gcloud storage cp:*)"
            "Bash(timber-git:*)"

            # --- WebSearch ---
            "WebSearch"

            # --- Websites ---
            "WebFetch(domain:pkg.go.dev)"
            "WebFetch(domain:go.dev)"
            "WebFetch(domain:golangci-lint.run)"
            "WebFetch(domain:github.com)"
            "WebFetch(domain:github.io)"
            "WebFetch(domain:gist.github.com)"
            "WebFetch(domain:raw.githubusercontent.com)"
            "WebFetch(domain:curtbushko.github.io)"
            "WebFetch(domain:stackoverflow.com)"
            "WebFetch(domain:modrinth.com)"
            "WebFetch(domain:api.modrinth.com)"
            "WebFetch(domain:ziglang.org)"
            "WebFetch(domain:zig.guide)"
            "WebFetch(domain:taskfile.dev)"
            "WebFetch(domain:www.shadertoy.com)"
            "WebFetch(domain:blog.maximeheckel.com)"
            "WebFetch(domain:www.youtube.com)"
            "WebFetch(domain:docs.obsidian.md)"
            "WebFetch(domain:support.atlassian.com)"
            "WebFetch(domain:community.atlassian.com)"
            "WebFetch(domain:jira.atlassian.com)"
            "WebFetch(domain:developer.box.com)"
            "WebFetch(domain:developers.zoom.us)"
            "WebFetch(domain:prow.ci.openshift.org)"
          ];
          deny = [];
          ask = [
            "Bash(rm:*)"
          ];
        };
        statusLine = {
          command = "node $HOME/.claude/statusline.mjs";
          padding = 0;
          type = "command";
        };
        theme = "dark";
      };
    };

    programs.zsh = {
      sessionVariables = {
        ANTHROPIC_MODEL = "claude-sonnet-4-5-20250929";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-5-20251101";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-5-20250929";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5-20251001";
        CLAUDE_CODE_EFFORT_LEVEL = "medium";
        CLAUDE_CODE_AUTO_COMPACT_WINDOW = "200000";
        CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1";
        CLAUDE_CODE_MAX_OUTPUT_TOKENS = "64000";
        MAX_THINKING_TOKENS = "31999";
        DISABLE_AUTOUPDATER = "1";
      };
      shellAliases = {
        cld = "TMUX= claude --model claude-sonnet-4-5-20250929 --effort medium";
        sonnet = "TMUX= claude --model claude-sonnet-4-5-20250929 --effort medium --dangerously-skip-permissions";
        opus = "TMUX= claude --model claude-opus-4-6 --effort medium --dangerously-skip-permissions";
      };
    };

    # Deploy Claude Code global instructions (CLAUDE.md)
    home.file.".claude/CLAUDE.md".source = ./claude/CLAUDE.md;

    # Deploy Claude Code skills
    home.file.".claude/skills".source = ./claude/skills;

    # Claude Code commands
    home.file.".claude/commands".source = ./claude/commands;

    # Claude Code agents
    home.file.".claude/agents".source = ./claude/agents;

    # Claude Code validation scripts
    home.file.".claude/scripts" = {
      source = ./claude/scripts;
      recursive = true;
      executable = true;
    };

    # Claude Code hooks (rtk rewrite, etc.)
    home.file.".claude/hooks" = {
      source = ./claude/hooks;
      recursive = true;
      executable = true;
    };

    # Claude Code statusline (Node.js for faster rendering)
    home.file.".claude/statusline.mjs" = {
      text = ''
        import { execSync } from "node:child_process";
        import { readFileSync } from "node:fs";

        const A_BG = "${a_bg}";
        const A_FG = "${a_fg}";
        const B_BG = "${b_bg}";
        const B_FG = "${b_fg}";
        const C_BG = "${c_bg}";
        const C_FG = "${c_fg}";
        const RESET = "\x1b[0m";
        const CLR = "\x1b[K";

        function hexToFg(hex) {
          const r = parseInt(hex.slice(1, 3), 16);
          const g = parseInt(hex.slice(3, 5), 16);
          const b = parseInt(hex.slice(5, 7), 16);
          return "\x1b[38;2;" + r + ";" + g + ";" + b + "m";
        }

        function hexToBg(hex) {
          const r = parseInt(hex.slice(1, 3), 16);
          const g = parseInt(hex.slice(3, 5), 16);
          const b = parseInt(hex.slice(5, 7), 16);
          return "\x1b[48;2;" + r + ";" + g + ";" + b + "m";
        }

        function run(cmd) {
          try {
            return execSync(cmd, { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim();
          } catch {
            return "";
          }
        }

        function extractModel(raw) {
          let m;
          // claude-3-5-sonnet -> sonnet-3.5
          m = raw.match(/claude-(\d+)-(\d+)-([a-z]+)/);
          if (m) return m[3] + "-" + m[1] + "." + m[2];
          // claude-sonnet-4-5 -> sonnet-4.5
          m = raw.match(/claude-([a-z]+)-(\d+)-(\d+)/);
          if (m) return m[1] + "-" + m[2] + "." + m[3];
          // claude-sonnet-4 -> sonnet-4
          m = raw.match(/claude-([a-z]+)-(\d+)\D/);
          if (m) return m[1] + "-" + m[2];
          return raw.slice(0, 10);
        }

        const input = JSON.parse(readFileSync(0, "utf8"));
        const branch = run("git branch --show-current");
        const rawModel = input.model?.display_name || "";

        // Icon: AWS Bedrock vs default
        const icon = /\.anthropic\./.test(rawModel) ? " " : "󱚝 ";

        // Repo name
        const gitCommon = run("git rev-parse --git-common-dir");
        let repo = "";
        if (gitCommon === ".git") {
          repo = run("git rev-parse --show-toplevel").split("/").pop() || "";
        } else if (gitCommon) {
          const parts = gitCommon.split("/");
          repo = parts[parts.length - 2] || "";
        }
        if (!repo) {
          repo = (input.workspace?.current_dir || "").split("/").pop() || "";
        }

        // Extract and center-pad model name
        const model = extractModel(rawModel);
        const width = 12;
        const padLeft = Math.floor((width - model.length) / 2);
        const padRight = width - model.length - padLeft;
        const modelPadded = " ".repeat(Math.max(0, padLeft)) + model + " ".repeat(Math.max(0, padRight));

        const sep = " ";

        // Build statusline
        let out = RESET;
        out += hexToBg(A_BG) + hexToFg(A_FG) + "▓▒░";
        out += hexToBg(A_BG) + hexToFg(A_FG) + " " + icon + modelPadded;
        out += hexToBg(B_BG) + hexToFg(A_BG) + sep;
        out += hexToBg(B_BG) + hexToFg(B_FG) + "󰊢 " + repo + " ";
        if (branch) {
          out += hexToBg(C_BG) + hexToFg(B_BG) + sep;
          out += hexToBg(C_BG) + hexToFg(C_FG) + " " + branch + " ";
          out += hexToFg(C_BG) + sep + RESET + CLR;
        } else {
          out += hexToFg(B_BG) + sep + RESET + CLR;
        }

        process.stdout.write(out);
      '';
    };
  };
}
