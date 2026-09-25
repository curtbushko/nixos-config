{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
  cfg = config.ns.llm;
  serveCfg = config.ns.llm.opencode.serve;
  opencode = inputs.opencode.packages.${pkgs.system}.opencode.overrideAttrs (_: {
    # OpenCode v2's completion command does not currently produce the files
    # expected by installShellCompletion, and its binary omits the commit
    # suffix used by the flake's version check.
    postInstall = "";
    postFixup = lib.optionalString pkgs.stdenv.isDarwin ''
      /usr/bin/codesign --force --sign - $out/bin/.opencode-wrapped
    '';
    doInstallCheck = false;
  });

  # Read colors from flair's style.json (same pattern as modules/home/styles/stylix.nix).
  # Requires --impure (Taskfile already passes it).
  flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";
  defaultColors = {
    base00 = "#1d2021";
    base01 = "#282828";
    base02 = "#3c3836";
    base03 = "#504945";
    base04 = "#bdae93";
    base05 = "#d4be98";
    base06 = "#ebdbb2";
    base07 = "#fbf1c7";
    base08 = "#ea6962";
    base09 = "#e78a4e";
    base0A = "#d8a657";
    base0B = "#a9b665";
    base0C = "#89b482";
    base0D = "#7daea3";
    base0E = "#d3869b";
    base0F = "#bd6f3e";
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

  # base16 → opencode theme mapping.
  # Opencode expects {dark, light} per entry; we use the same color for both
  # because the flair theme already commits to one polarity.
  c = k: {
    dark = colors.${k};
    light = colors.${k};
  };

  a_bg = colors."statusline-a-bg";
  a_fg = colors."statusline-a-fg";
  b_bg = colors."statusline-b-bg";
  b_fg = colors."statusline-b-fg";
  c_bg = colors."statusline-c-bg";
  c_fg = colors."statusline-c-fg";

  flairTheme = {
    "$schema" = "https://opencode.ai/theme.json";
    theme = {
      # Core UI
      # Match ghostty which uses base01 as the terminal background.
      background = c "base01";
      # Keep user messages and the prompt on the terminal background, like Claude Code.
      backgroundPanel = c "base00";
      backgroundElement = c "base00";
      text = c "base05";
      textMuted = c "base04";
      border = c "base03";
      borderSubtle = c "base02";
      borderActive = c "base0D";
      primary = c "base0D";
      secondary = c "base0E";
      accent = c "base0C";
      # Status
      error = c "base08";
      warning = c "base09";
      success = c "base0B";
      info = c "base0D";
      # Diff
      diffAdded = c "base0B";
      diffRemoved = c "base08";
      diffContext = c "base03";
      diffHunkHeader = c "base0C";
      # Markdown
      markdownHeading = c "base0A";
      markdownStrong = c "base09";
      markdownEmph = c "base0E";
      markdownCode = c "base0B";
      markdownLink = c "base0D";
      markdownLinkText = c "base0D";
      markdownBlockQuote = c "base04";
      # Syntax
      syntaxKeyword = c "base0E";
      syntaxString = c "base0B";
      syntaxNumber = c "base09";
      syntaxComment = c "base03";
      syntaxType = c "base0A";
      syntaxFunction = c "base0D";
      syntaxVariable = c "base08";
      syntaxOperator = c "base05";
      syntaxPunctuation = c "base05";
    };
  };

  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    experimental.policies = [
      {
        action = "provider.use";
        resource = "*";
        effect = "deny";
      }
      {
        action = "provider.use";
        resource = "openai";
        effect = "allow";
      }
      {
        action = "provider.use";
        resource = "github-copilot";
        effect = "allow";
      }
    ];
  };

  opencodeTuiConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "flair";
    plugin = ["./plugins/claude-statusline.tsx"];
  };

  opencodePasswordFile = config.sops.secrets."OPENCODE_PASSWORD".path;

  opencodeServeWrapper = pkgs.writeShellScript "opencode-serve" ''
    set -eu
    export OPENCODE_PASSWORD="$(cat ${opencodePasswordFile})"
    exec ${opencode}/bin/opencode serve --service --hostname 0.0.0.0 --port 4096
  '';
in {
  options.ns.llm.opencode.serve.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Whether to run the opencode server as a launchd agent on this host.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      opencode
    ];

    launchd.agents.opencode = lib.mkIf (pkgs.stdenv.isDarwin && serveCfg.enable) {
      enable = true;
      config = {
        ProgramArguments = [(toString opencodeServeWrapper)];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/opencode.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/opencode.err";
      };
    };

    xdg.configFile."opencode/config.json".text = opencodeConfig;
    xdg.configFile."opencode/tui.json".text = opencodeTuiConfig;
    xdg.configFile."opencode/themes/flair.json".text = builtins.toJSON flairTheme;
    xdg.configFile."opencode/plugins/claude-statusline.tsx".text = ''
      /** @jsxImportSource @opentui/solid */
      import type { TuiPlugin, TuiPluginApi } from "@opencode-ai/plugin/tui"
      import { createMemo, Show } from "solid-js"

      const A_BG = "${a_bg}"
      const A_FG = "${a_fg}"
      const B_BG = "${b_bg}"
      const B_FG = "${b_fg}"
      const C_BG = "${c_bg}"
      const C_FG = "${c_fg}"
      const REPO_ICONS: Record<string, string> = {
        kb: "󰧑",
        "nixos-config": "󱄅",
        ghostty: "󰊠",
        "neovim-flake": "",
        terraform: "󱁢",
        Downloads: "",
      }

      function StatusLine(props: { api: TuiPluginApi }) {
        const sessionID = createMemo(() => {
          const route = props.api.route.current
          return route.name === "session" ? route.params.sessionID : undefined
        })
        const session = createMemo(() => {
          const id = sessionID()
          return id ? props.api.state.session.get(id) : undefined
        })
        const lastUserMessage = createMemo(() => {
          const id = sessionID()
          return id ? props.api.state.session.messages(id).findLast((message) => message.role === "user") : undefined
        })
        const model = createMemo(() => {
          const message = lastUserMessage()
          if (!message || message.role !== "user") return "opencode"
          return message.model.modelID
        })
        const repo = createMemo(() => {
          const directory = session()?.directory || props.api.state.path.directory
          return directory.split("/").filter(Boolean).at(-1) || directory
        })
        const repoIcon = createMemo(() => REPO_ICONS[repo()] || "󰊢")
        const branch = createMemo(() => {
          if (session()?.directory !== props.api.state.path.directory) return
          return props.api.state.vcs?.branch
        })

        return (
          <Show when={sessionID()}>
            <box width="100%" flexDirection="row" flexShrink={0}>
              <text>
                <span style={{ bg: C_BG, fg: C_BG }}> </span>
                <span style={{ bg: A_BG, fg: A_FG }}>▓▒░ 󰭹 {model()} </span>
                <span style={{ bg: B_BG, fg: A_BG }}> </span>
                <span style={{ bg: B_BG, fg: B_FG }}> {repoIcon()} {repo()} </span>
                <Show when={branch()}>
                  {(name) => (
                    <>
                      <span style={{ bg: C_BG, fg: B_BG }}> </span>
                      <span style={{ bg: C_BG, fg: C_FG }}> {name()} </span>
                    </>
                  )}
                </Show>
              </text>
            </box>
          </Show>
        )
      }

      const tui: TuiPlugin = async (api) => {
        api.slots.register({
          order: 100,
          slots: {
            app_bottom() {
              return <StatusLine api={api} />
            },
          },
        })
      }

      export default {
        id: "curtbushko.claude-statusline",
        tui,
      }
    '';

    programs.zsh.shellAliases =
      {
        ocode = "opencode";
        remotecode = "opencode --server http://curtbushko-K4W6XK6XND:4096";
      }
      // lib.optionalAttrs serveCfg.enable {
        ocode-connect = "OPENCODE_PASSWORD=\"$(cat ${opencodePasswordFile})\" opencode --server http://localhost:4096";
      };
  };
}
