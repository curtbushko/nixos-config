{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.llm;

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

  cdx = pkgs.writeShellScriptBin "cdx" ''
    set -euo pipefail

    export CODEX_HOME="''${CODEX_HOME:-${config.home.homeDirectory}/.config/codex}"

    trust_root="$PWD"
    if common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
      trust_root="$(dirname "$common_dir")"
    fi

    project_key="''${trust_root//\\/\\\\}"
    project_key="''${project_key//\"/\\\"}"

    exec codex -m gpt-5.5 -c "projects={\"''${project_key}\"={trust_level=\"trusted\"}}" "$@"
  '';
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.codex
      cdx
    ];

    programs.zsh = {
      sessionVariables = {
        CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      };
      shellAliases = {
        cx = "codex";
      };
    };

    # Deploy Codex global instructions (AGENTS.md)
    home.file.".config/codex/AGENTS.md".source = ./codex/AGENTS.md;

    # Deploy Codex skills as individual SKILL.md files
    home.file.".config/codex/skills".source = ./codex/skills;

    # Deploy Codex command approval rules.
    home.file.".config/codex/rules".source = ./codex/rules;

    # Codex statusline configuration
    home.file.".config/codex/config.toml".text = ''
      approval_policy = "never"
      sandbox_mode    = "workspace-write"
      file_opener     = "none"
      reasoning_effort = "medium"
      commit_attribution = ""
      web_search = "live"

      status_line = { command = "node $HOME/.config/codex/statusline.mjs", padding = 0, type = "command" }

      [sandbox_workspace_write]
      readable_roots = [ "${config.home.homeDirectory}/.config/codex/sessions" ]
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
      inherit                 = "core"          # all | core | none
      ignore_default_excludes = false           # if false, KEY/SECRET/TOKEN names are stripped first
      include_only            = ["PATH", "HOME", "TMPDIR", "LANG", "LC_*"]
      exclude                 = ["AWS_*", "GITHUB_*", "*_TOKEN", "*_SECRET", "*_KEY"]
      set                     = { "CI" = "1", "NO_COLOR" = "1", "USER" = "${config.home.username}", "LOGNAME" = "${config.home.username}", "PATH" = "${config.home.homeDirectory}/.local/bin:/run/wrappers/bin:${config.home.homeDirectory}/.nix-profile/bin:/nix/profile/bin:${config.home.homeDirectory}/.local/state/nix/profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin" }
      experimental_use_profile = false

      [projects."${config.home.homeDirectory}/workspace/github.com/curtbushko/nixos-config"]
      trust_level = "trusted"
    '';

    # Codex statusline (Node.js for faster rendering)
    home.file.".config/codex/statusline.mjs" = {
      text = ''
        import { execSync } from "node:child_process";
        import { readdirSync, readFileSync, statSync } from "node:fs";
        import { join } from "node:path";

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

        function normalizeLimitLabel(label, fallback) {
          const normalized = (label || fallback || "").toLowerCase().replace(/[_\s]+/g, "-");
          if (normalized === "five-hour-limit") return "5h";
          if (normalized === "weekly-limit") return "week";
          return label || fallback;
        }

        function formatLimit(limit, fallback) {
          const label = normalizeLimitLabel(limit?.limit_name, fallback);
          if (typeof limit?.used_percent === "number") {
            return label + " " + Math.round(limit.used_percent) + "%";
          }

          return label;
        }

        function renderLimitSegment(limit, fallback, bg, fg, prevBg) {
          const content = formatLimit(limit, fallback);
          return (
            hexToBg(bg) +
            hexToFg(prevBg) +
            " " +
            hexToBg(bg) +
            hexToFg(fg) +
            " " +
            content +
            " "
          );
        }

        function findLatestSessionFile(root) {
          let latestFile = "";
          let latestMtime = 0;
          const stack = [root];

          while (stack.length > 0) {
            const current = stack.pop();
            if (!current) continue;

            let entries = [];
            try {
              entries = readdirSync(current, { withFileTypes: true });
            } catch {
              continue;
            }

            for (const entry of entries) {
              const path = join(current, entry.name);
              if (entry.isDirectory()) {
                stack.push(path);
                continue;
              }

              if (!entry.isFile() || !entry.name.endsWith(".jsonl")) {
                continue;
              }

              let mtimeMs = 0;
              try {
                mtimeMs = statSync(path).mtimeMs;
              } catch {
                continue;
              }

              if (mtimeMs > latestMtime) {
                latestMtime = mtimeMs;
                latestFile = path;
              }
            }
          }

          return latestFile;
        }

        function readLatestRateLimits() {
          if (!process.env.CODEX_HOME) {
            return {};
          }

          const sessionRoot = process.env.CODEX_HOME + "/sessions";
          const latestFile = findLatestSessionFile(sessionRoot);
          if (!latestFile) {
            return {};
          }

          let content = "";
          try {
            content = readFileSync(latestFile, "utf8");
          } catch {
            return {};
          }

          const lines = content.trim().split("\n").reverse();
          for (const line of lines) {
            if (!line) continue;

            try {
              const event = JSON.parse(line);
              if (event?.type === "event_msg" && event?.payload?.type === "token_count" && event.payload.rate_limits) {
                return event.payload.rate_limits;
              }
            } catch {
              continue;
            }
          }

          return {};
        }

        const input = JSON.parse(readFileSync(0, "utf8"));
        const branch = run("git branch --show-current");
        const rawModel = input.model?.display_name || "";
        const directRateLimits = input.rate_limits || {};
        const rateLimits = Object.keys(directRateLimits).length > 0 ? directRateLimits : readLatestRateLimits();

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
        let currentBg = B_BG;
        if (branch) {
          out += hexToBg(C_BG) + hexToFg(B_BG) + sep;
          out += hexToBg(C_BG) + hexToFg(C_FG) + " " + branch + " ";
          currentBg = C_BG;
        }

        const fiveHourLimit =
          rateLimits.primary ||
          rateLimits.five_hour_limit ||
          rateLimits.fiveHourLimit ||
          rateLimits["five-hour-limit"] ||
          {};
        const weeklyLimit =
          rateLimits.secondary ||
          rateLimits.weekly_limit ||
          rateLimits.weeklyLimit ||
          rateLimits["weekly-limit"] ||
          {};

        out += renderLimitSegment(fiveHourLimit, "five-hour-limit", B_BG, B_FG, currentBg);
        currentBg = B_BG;
        out += renderLimitSegment(weeklyLimit, "weekly-limit", C_BG, C_FG, currentBg);
        currentBg = C_BG;
        out += hexToFg(currentBg) + sep + RESET + CLR;

        process.stdout.write(out);
      '';
    };

    # Deploy Codex helper scripts.
    home.file.".config/codex/scripts" = {
      source = ./codex/scripts;
      recursive = true;
      executable = true;
    };
  };
}
