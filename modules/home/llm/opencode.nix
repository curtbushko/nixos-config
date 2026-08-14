{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.llm;

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

  flairTheme = {
    "$schema" = "https://opencode.ai/theme.json";
    theme = {
      # Core UI
      # Match ghostty which uses base01 as the terminal background.
      background = c "base01";
      backgroundPanel = c "base00";
      backgroundElement = c "base02";
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
    theme = "flair";
    provider = {
      gamingrig = {
        name = "gamingrig llama-server";
        npm = "@ai-sdk/openai-compatible";
        env = [];
        options = {
          apiKey = "not-needed";
          baseURL = "http://gamingrig:8080/v1";
        };
        models = {
          "qwen3.8-27b" = {
            name = "Qwen3.8-27B (unsloth)";
            tool_call = true;
            reasoning = true;
          };
        };
      };
    };
  };
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.opencode
    ];

    xdg.configFile."opencode/config.json".text = opencodeConfig;
    xdg.configFile."opencode/themes/flair.json".text = builtins.toJSON flairTheme;

    programs.zsh = {
      shellAliases = {
        ocode = "opencode";
      };
    };
  };
}
