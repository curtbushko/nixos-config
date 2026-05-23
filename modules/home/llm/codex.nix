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
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      codex
    ];


    programs.zsh = {
      sessionVariables = {
        CODEX_HOME = "${config.home.homeDirectory}/.codex";
        OPENAI_API_KEY = ""; # Set via environment or secrets management
      };
      shellAliases = {
        cx = "codex";
      };
    };

    # Deploy Codex global instructions (AGENTS.md)
    home.file.".codex/AGENTS.md".source = ./codex/AGENTS.md;

    # Deploy Codex skills as individual AGENTS.md files
    home.file.".codex/skills".source = ./codex/skills;

    # Codex statusline configuration
    home.file.".codex/config.toml".text = ''
      model = "gpt-5.4"
      reasoning_effort = "medium"
      status_line = { command = "node $HOME/.codex/statusline.mjs", padding = 0, type = "command" }

      [sandbox_workspace_write]
      readable_roots = [ "${config.home.homeDirectory}/.codex/sessions" ]
    '';

    # Codex statusline (Node.js for faster rendering)
    home.file.".codex/statusline.mjs" = {
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
        const rateLimits = input.rate_limits || {};

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
        } else {
          out += hexToFg(B_BG) + sep;
        }

        function formatLimit(limit, fallback) {
          const label = limit?.limit_name || fallback;
          if (typeof limit?.used_percent === "number") {
            return label + " " + Math.round(limit.used_percent) + "%";
          }

          return label;
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

        out += hexToBg(C_BG) + hexToFg(C_FG) + " " + formatLimit(fiveHourLimit, "five-hour-limit");
        out += " " + formatLimit(weeklyLimit, "weekly-limit") + " ";
        out += hexToFg(C_BG) + sep + RESET + CLR;

        process.stdout.write(out);
      '';
    };

    # Codex validation scripts
    home.file.".codex/scripts" = {
      source = ./codex/scripts;
      recursive = true;
      executable = true;
    };
  };
}
