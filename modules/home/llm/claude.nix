{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.llm;
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
        command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
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
  };
}
