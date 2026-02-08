{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.llm;
  colors = lib.importJSON ../../home/styles/${config.curtbushko.theme.name}.json;
  a_bg = colors.statusline_a_bg;
  a_fg = colors.statusline_a_fg;
  b_bg = colors.statusline_b_bg;
  b_fg = colors.statusline_b_fg;
  c_bg = colors.statusline_c_bg;
  c_fg = colors.statusline_c_fg;
in {
  config = mkIf cfg.enable {
    programs.claude-code = {
    enable = true;
    package = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      includeCoAuthoredBy = false;
      hooks = {
        SessionStart = [
          {
            matcher = "startup|resume|clear|compact";
            hooks = [
              {
                type = "command";
                timeout = 10;
                command = ''
                  # Ensure Go config files exist in curtbushko repos
                  if [ -x "$HOME/.claude/scripts/ensure-go-configs.sh" ]; then
                    "$HOME/.claude/scripts/ensure-go-configs.sh" "$(pwd)"
                  fi
                '';
              }
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
        allow = [
          "Bash(make:*)"
          "Bash(go:*)"
          "Bash(ls:*)"
          "Bash(find:*)"
          "Bash(rg:*)"
          "Bash(grep:*)"
          "Bash(cat:*)"
          "Bash(mkdir:*)"
          "Bash(curl:*)"
          "Bash(do)"
          "Bash(echo:*)"
          "Bash(done)"
          "Bash(journalctl:*)"
          "Bash(sudo ls:*)"
          "Bash(sudo cat:*)"
          "Bash(sudo systemctl:*)"
          "Bash(systemctl status:*)"
          "Bash(sudo tail:*)"
          "Bash(nix search:*)"
          "Bash(chmod:*)"
          "Bash(nix-option:*)"
          "Bash(unzip:*)"
          "WebFetch(domain:pkg.go.dev)"
          "WebFetch(domain:github.com)"
          "WebFetch(domain:github.io)"
          "WebFetch(domain:stackoverflow.com)"
          "WebFetch(domain:go.dev)"
          "WebFetch(domain:golangci-lint.run)"
          "WebFetch(domain:gist.github.com)"
          "WebFetch(domain:modrinth.com)"
          "WebFetch(domain:api.modrinth.com)"
          "WebFetch(domain:ziglang.org)"
          "WebFetch(domain:zig.guide)"
          "Bash(golangci-lint run)"
          "Bash(go-arch-lint check)"
          "Bash(go-ai-lint ./...)"
        ];
        deny = [ ];
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
