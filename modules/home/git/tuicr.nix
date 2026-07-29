{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.git;
in {
  config = mkIf cfg.enable {
    home.packages = [
      inputs.tuicr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    programs.zsh.shellAliases.review = "tuicr";

    # tuicr: config + local flair theme derived from flair's style.json.
    # Requires --impure because flair colors are read at eval time.
    xdg.configFile."tuicr/config.toml".text = ''
      theme = "flair"
    '';

    xdg.configFile."tuicr/themes/flair.toml".text = let
      flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

      defaultColors = {
        base00 = "#2d353b";
        base01 = "#232a2e";
        base02 = "#343f44";
        base03 = "#859289";
        base04 = "#9da9a0";
        base05 = "#d3c6aa";
        base08 = "#e67e80";
        base09 = "#e69875";
        base0A = "#dbbc7f";
        base0B = "#a7c080";
        base0C = "#83c092";
        base0D = "#7fbbb3";
        base0E = "#d0a4de";
      };

      colors =
        if builtins.pathExists flairStylePath
        then builtins.fromJSON (builtins.readFile flairStylePath)
        else defaultColors;

      panelBg = colors."surface-bg" or colors.base00;
      bgHighlight = colors."surface-bg-highlight" or colors.base02;
      fgPrimary = colors.base05;
      fgSecondary = colors.base04 or colors.base05;
      fgDim = colors.base03;
      # diff_add/diff_del are the fg of added/removed lines, not the sign color.
      # flair's diff-added-fg / diff-deleted-fg is the normal fg over the diff bg.
      diffAdd = colors."diff-added-fg" or colors.base05;
      diffAddBg = colors."diff-added-bg" or colors.base02;
      diffDel = colors."diff-deleted-fg" or colors.base05;
      diffDelBg = colors."diff-deleted-bg" or colors.base02;
      diffHunkHeader = colors.base0D;
      fileAdded = colors."git-added" or colors.base0B;
      fileModified = colors."git-modified" or colors.base0D;
      fileDeleted = colors."git-deleted" or colors.base08;
      fileRenamed = colors.base0E;
      statusSuccess = colors."status-success" or colors.base0B;
      statusWarning = colors."status-warning" or colors.base0A;
      statusError = colors."status-error" or colors.base08;
      statusInfo = colors."status-info" or colors.base0D;
      borderFocused = colors."border-focus" or colors.base0D;
      borderUnfocused = colors."border-muted" or colors.base02;
      statusBarBg = colors."surface-bg-statusbar" or colors.base01;
      cursorLineBg = colors."state-hover" or colors.base02;
      badgeFg = colors.base00;
      modeBg = colors."statusline-a-bg" or colors.base0D;
      modeFg = colors."statusline-a-fg" or colors.base00;
    in ''
      # Generated from flair's style.json. Do not edit; update flair instead.
      panel_bg = "${panelBg}"
      bg_highlight = "${bgHighlight}"
      fg_primary = "${fgPrimary}"
      fg_secondary = "${fgSecondary}"
      fg_dim = "${fgDim}"

      diff_add = "${diffAdd}"
      diff_add_bg = "${diffAddBg}"
      diff_del = "${diffDel}"
      diff_del_bg = "${diffDelBg}"
      diff_context = "${fgPrimary}"
      diff_hunk_header = "${diffHunkHeader}"
      expanded_context_fg = "${fgDim}"

      syntax_add_bg = "${diffAddBg}"
      syntax_del_bg = "${diffDelBg}"

      file_added = "${fileAdded}"
      file_modified = "${fileModified}"
      file_deleted = "${fileDeleted}"
      file_renamed = "${fileRenamed}"

      reviewed = "${statusSuccess}"
      pending = "${statusWarning}"

      comment_note = "${colors.base0D}"
      comment_suggestion = "${colors.base0C or colors.base0D}"
      comment_issue = "${statusError}"
      comment_praise = "${statusSuccess}"

      border_focused = "${borderFocused}"
      border_unfocused = "${borderUnfocused}"
      status_bar_bg = "${statusBarBg}"
      cursor_color = "${colors.base0A or colors.base09}"
      cursor_line_bg = "${cursorLineBg}"
      branch_name = "${colors.base0E}"
      help_indicator = "${fgDim}"

      message_info_fg = "${badgeFg}"
      message_info_bg = "${statusInfo}"
      message_warning_fg = "${badgeFg}"
      message_warning_bg = "${statusWarning}"
      message_error_fg = "${badgeFg}"
      message_error_bg = "${statusError}"
      update_badge_fg = "${badgeFg}"
      update_badge_bg = "${statusWarning}"

      mode_fg = "${modeFg}"
      mode_bg = "${modeBg}"
    '';
  };
}
