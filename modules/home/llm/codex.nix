{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapStringsSep filterAttrs mkIf;
  cfg = config.ns.llm;
  codexPkgs = inputs.codex-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  workspacePath = "${config.home.homeDirectory}/workspace";
  workspaceDirectories = let
    readDirectories = path:
      if builtins.pathExists path
      then
        map
        (name: "${path}/${name}")
        (builtins.attrNames (filterAttrs (_: type: type == "directory") (builtins.readDir path)))
      else [];
    levelOne = readDirectories workspacePath;
    levelTwo = builtins.concatMap readDirectories levelOne;
    levelThree = builtins.concatMap readDirectories levelTwo;
  in
    levelOne ++ levelTwo ++ levelThree;
  trustedWorkspaceProjects =
    concatMapStringsSep "\n" (path: ''
      [projects."${path}"]
      trust_level = "trusted"
    '')
    workspaceDirectories;

in {
  config = mkIf cfg.enable {
    home.packages = [
      codexPkgs.codex
    ];

    programs.zsh = {
      sessionVariables = {
        CODEX_HOME = "${config.home.homeDirectory}/.codex";
      };
      shellAliases = {
        cx = "codex";
      };
    };

    # SessionStart hook: prune rollout JSONLs older than 30 days into a
    # sibling trash dir. Runs async so it does not block session startup.
    home.file.".codex/hooks.json".text = builtins.toJSON {
      hooks.SessionStart = [
        {
          hooks = [
            {
              type = "command";
              async = true;
              command = ''
                sessions="''${CODEX_HOME:-$HOME/.codex}/sessions"
                trash="''${CODEX_HOME:-$HOME/.codex}/sessions-trash"
                [ -d "$sessions" ] || exit 0
                mkdir -p "$trash"
                find "$sessions" -type f -name '*.jsonl' -mtime +30 \
                  -exec mv -t "$trash" {} + 2>/dev/null
                find "$sessions" -mindepth 1 -type d -empty -delete 2>/dev/null
                exit 0
              '';
            }
          ];
        }
      ];
    };

    # Deploy Codex global instructions (AGENTS.md)
    home.file.".codex/AGENTS.md".source = ./codex/AGENTS.md;

    # Deploy Agent Skills from the canonical, host-neutral source directory.
    # The same ./skills tree is also consumed by Claude Code (see claude.nix).
    home.file.".codex/skills".source = ./skills;

    # Deploy Codex command approval rules.
    home.file.".codex/rules".source = ./codex/rules;

    # Deploy Codex subagent definitions (TOML). Codex uses a different agent
    # format than Claude Code (which uses Markdown in ./claude/agents), so these
    # cannot share one canonical source the way ./skills does.
    home.file.".codex/agents".source = ./codex/agents;

    # Codex statusline configuration
    home.file.".codex/config.toml".text = ''
      approval_policy = "never"
      sandbox_mode    = "danger-full-access"
      file_opener     = "none"
      reasoning_effort = "medium"
      commit_attribution = ""
      web_search = "live"

      [features]
      memories = true

      # Codex currently supports built-in status-line items only. Command-backed
      # status lines and ANSI styling are tracked upstream in openai/codex#17827.
      [tui]
      status_line = ["model-with-reasoning", "current-dir", "git-branch", "five-hour-limit", "weekly-limit"]

      [sandbox_workspace_write]
      readable_roots = [ "${config.home.homeDirectory}/.codex/sessions" ]
      network_access = true

      [features.network_proxy]
      enabled = true

      [features.network_proxy.domains]
      "api.github.com" = "allow"
      "api.modrinth.com" = "allow"
      "gist.github.com" = "allow"
      "github.com" = "allow"
      "github.io" = "allow"
      "go.dev" = "allow"
      "golangci-lint.run" = "allow"
      "modrinth.com" = "allow"
      "pkg.go.dev" = "allow"
      "raw.githubusercontent.com" = "allow"
      "stackoverflow.com" = "allow"
      "zig.guide" = "allow"
      "ziglang.org" = "allow"

      [shell_environment_policy]
      inherit                 = "all"           # all | core | none
      ignore_default_excludes = false           # if false, KEY/SECRET/TOKEN names are stripped first
      include_only            = ["PATH", "HOME", "TMPDIR", "LANG", "LC_*", "USER", "LOGNAME"]
      exclude                 = ["AWS_*", "GITHUB_*", "*_TOKEN", "*_SECRET", "*_KEY"]
      set                     = { "CI" = "1", "NO_COLOR" = "1" }
      experimental_use_profile = true

      ${trustedWorkspaceProjects}

      # Subagents: auto-discovered from ~/.codex/agents/*.toml. Reviewers run
      # read-only and the builder runs workspace-write, per each agent's own
      # sandbox_mode. Model is inherited from the parent thread unless an agent
      # overrides it.
      [agents]
      enabled = true
      max_concurrent_threads_per_session = 4
      default_subagent_reasoning_effort = "medium"
    '';


    # Deploy Codex helper scripts.
    home.file.".codex/scripts" = {
      source = ./codex/scripts;
      recursive = true;
      executable = true;
    };
  };
}
