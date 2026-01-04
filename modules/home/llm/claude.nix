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
          git_common=$(git rev-parse --git-common-dir 2>/dev/null)
          if [ "$git_common" = ".git" ]; then
            repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
          else
            repo=$(basename "$(dirname "$git_common")")
          fi
          model=$(echo "$input" | jq -r '.model.display_name')
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
          printf "%b" "''${a_bg_code}''${a_fg_code} 󱚝 ''${model_padded}"
          printf "%b""''${b_bg_code}$(hex_to_ansi "${a_bg}")''${sep}"
          printf "%b""''${b_bg_code}''${b_fg_code}󰊢 ''${repo:-$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")} "
          if [ -n "$branch" ]; then
            printf "%b" "''${c_bg_code}$(hex_to_ansi "${b_bg}")''${sep}"
            printf "%b" "''${c_bg_code}''${c_fg_code} ''${branch} "
            printf "%b" "$(hex_to_ansi "${c_bg}")''${sep}''${reset}"
          else
            printf "%b" "$(hex_to_ansi "${b_bg}")''${sep}''${reset}"
          fi
          echo
        '';
        padding = 0;
        type = "command";
      };
      theme = "dark";
    };
  };

    # Deploy Claude Code skills
    home.file.".claude/skills/bash.md".source = ./claude/skills/bash.md;
    home.file.".claude/skills/golang.md".source = ./claude/skills/golang.md;
    home.file.".claude/skills/start-project.md".source = ./claude/skills/start-project.md;
    home.file.".claude/skills/minecraft-mods.md".source = ./claude/skills/minecraft-mods.md;
    home.file.".claude/skills/go-code-review/SKILL.md".source = ./claude/skills/go-code-review/SKILL.md;
    home.file.".claude/skills/go-code-review/knowledge-base.md".source = ./claude/skills/go-code-review/knowledge-base.md;
    home.file.".claude/skills/go-code-review/real-world-patterns.md".source = ./claude/skills/go-code-review/real-world-patterns.md;

    # Claude Code commands
    home.file.".claude/commands/cleanup-code.md".source = ./claude/commands/cleanup-code.md;
    home.file.".claude/commands/docs-review.md".source = ./claude/commands/docs-review.md;
    home.file.".claude/commands/pr-review.md".source = ./claude/commands/pr-review.md;

  };
}
