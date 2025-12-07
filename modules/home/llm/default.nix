{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.llm;
in {
  options.curtbushko.llm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable llm
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        includeCoAuthoredBy = false;
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
            "WebFetch(domain:pkg.go.dev)"
            "WebFetch(domain:*.github.com)"
            "WebFetch(domain:*.github.io)"
            "WebFetch(domain:*.stackoverflow.com)"
            "WebFetch(domain:go.dev)"
            "WebFetch(domain:golangci-lint.run)"
            "WebFetch(domain:gist.github.com)"
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
    home.file.".claude/skills/golang.md".source = ./claude/skills/golang.md;
  };
}
