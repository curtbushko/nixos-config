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
        ];
        deny = [ ];
        ask = [
          "Bash(rm:*)"
        ];
      };
      statusLine = {
        command = ''
          input=$(cat)
          branch=$(git branch --show-current 2>/dev/null)
          aws_icon=" "
          default_icon="󱚝 "
          # Select icon based on whether model is from AWS Bedrock
          raw_model=$(echo "$input" | jq -r '.model.display_name')
          if echo "$raw_model" | grep -qE '\.anthropic\.' ; then
            icon="$aws_icon"
          else
            icon="$default_icon"
          fi
          git_common=$(git rev-parse --git-common-dir 2>/dev/null)
          if [ "$git_common" = ".git" ]; then
            repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
          else
            repo=$(basename "$(dirname "$git_common")")
          fi
          # Extract model family and version from various formats:
          # - "global.anthropic.claude-sonnet-4-5-20250929-v1:0" -> "sonnet-4.5"
          # - "claude-opus-4-5-20251101" -> "opus-4.5"
          # - "claude-3-5-sonnet-20241022" -> "sonnet-3.5"
          model=$(echo "$raw_model" | sed -E '
            # Handle claude-X-Y-family format (e.g., claude-3-5-sonnet)
            s/.*claude-([0-9]+)-([0-9]+)-([a-z]+).*/\3-\1.\2/;
            t done;
            # Handle family-X-Y format (e.g., claude-sonnet-4-5)
            s/.*claude-([a-z]+)-([0-9]+)-([0-9]+).*/\1-\2.\3/;
            t done;
            # Handle family-X format (e.g., claude-sonnet-4)
            s/.*claude-([a-z]+)-([0-9]+)[^0-9].*/\1-\2/;
            t done;
            :done
          ')
          # Fallback: truncate to 10 chars if extraction failed
          if [ "$model" = "$raw_model" ] || [ -z "$model" ]; then
            model=$(echo "$raw_model" | cut -c1-10)
          fi
          width=12
          len=''${#model}
          pad=$(( (width - len) / 2 ))
          pad_right=$(( width - len - pad ))
          model_padded=$(printf "%*s%s%*s" "$pad" "" "$model" "$pad_right" "")

          # Convert hex colors to ANSI escape codes
          hex_to_ansi() {
            hex=''${1#\#}
            r=$((16#''${hex:0:2}))
            g=$((16#''${hex:2:2}))
            b=$((16#''${hex:4:2}))
            echo "\033[38;2;''${r};''${g};''${b}m"
          }

          hex_to_ansi_bg() {
            hex=''${1#\#}
            r=$((16#''${hex:0:2}))
            g=$((16#''${hex:2:2}))
            b=$((16#''${hex:4:2}))
            echo "\033[48;2;''${r};''${g};''${b}m"
          }

          a_bg_code=$(hex_to_ansi_bg "${a_bg}")
          a_fg_code=$(hex_to_ansi "${a_fg}")
          b_bg_code=$(hex_to_ansi_bg "${b_bg}")
          b_fg_code=$(hex_to_ansi "${b_fg}")
          c_bg_code=$(hex_to_ansi_bg "${c_bg}")
          c_fg_code=$(hex_to_ansi "${c_fg}")
          reset="\033[0m"
          sep=" "

          # Build the statusline
          printf "%b""''${a_bg_code}''${a_fg_code}▓▒░"
          printf "%b" "''${a_bg_code}''${a_fg_code} ''${icon}''${model_padded}"
          printf "%b""''${b_bg_code}$(hex_to_ansi "${a_bg}")''${sep}"
          printf "%b""''${b_bg_code}''${b_fg_code}󰊢 ''${repo:-$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")} "
          if [ -n "$branch" ]; then
            printf "%b" "''${c_bg_code}$(hex_to_ansi "${b_bg}")''${sep}"
            printf "%b" "''${c_bg_code}''${c_fg_code} ''${branch} "
            printf "%b" "$(hex_to_ansi "${c_bg}")''${sep}''${reset}\033[K"
          else
            printf "%b" "$(hex_to_ansi "${b_bg}")''${sep}''${reset}\033[K"
          fi
        '';
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

  };
}
