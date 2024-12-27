{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.curtbushko.terminals;
in
{
  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      tmuxinator.enable = true;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        yank
      ];
      newSession = true;
      sensibleOnTop = false;
      disableConfirmationPrompt = true;
      extraConfig = let
        section1 = "fg=#${config.lib.stylix.colors.base01},bg=#${config.lib.stylix.colors.base06}";
        #section2 = "fg=#${config.lib.stylix.colors.base06},bg=#${config.lib.stylix.colors.base0D}";
        #section3 = "fg=#${config.lib.stylix.colors.base0D},bg=#${config.lib.stylix.colors.base03}";
        separator1 = "fg=#${config.lib.stylix.colors.base06},bg=#${config.lib.stylix.colors.base0D}";
        #separator2 = "fg=#${config.lib.stylix.colors.base0D},bg=#${config.lib.stylix.colors.base03}";
        #separator3 = "fg=#${config.lib.stylix.colors.base03},bg=#${config.lib.stylix.colors.base05}";
        active = "${config.lib.stylix.colors.base08}";

        background = "${config.lib.stylix.colors.base00}";
        foreground = "${config.lib.stylix.colors.base06}";
      in ''
        set -g mouse on
        set -g set-clipboard on
        set -g history-limit 102400
        set -g base-index 1
        set -g pane-base-index 1
        set -g renumber-windows on
        setw -g mode-keys vi
        set -g escape-time 10
        # enable auto renaming
        setw -g automatic-rename on

        # enable wm window titles
        set -g set-titles on

        # hostname, window number, program name
        set -g set-titles-string '#H: #S.#I.#P #W'

        # monitor activity between windows
        setw -g monitor-activity on
        set -g visual-activity on

        set -g status-left '░▒▓#[${section1}]   #[${separator1}]'
        set -g status-right ' #[${background}] #{user}@#{session_name} '
        set -g status-bg '#${background}'
        set -g status-fg '#${foreground}'
        set-option -g status-position bottom
        set -g pane-border-style bg=default,fg='#${foreground}'
        set -g pane-active-border-style bg=default,fg=#${active},bold
        set -g display-panes-colour '#${foreground}'
        set -g display-panes-active-colour '#${active}'
        # inactive status color
        set -g window-status-style fg=#${config.lib.stylix.colors.base06},bg=#${config.lib.stylix.colors.base0D}
        # active status
        set -g window-status-current-style fg=#${config.lib.stylix.colors.base08},bg=#${config.lib.stylix.colors.base0D}
      '';
    };

    home.file = {
      ".config/tmuxinator/home.yml" = {
        text = ''
          name: home
          startup_window: 1
          root: ~/
          windows:
          - codeone:
              # 2 pane layout - line in middle of camera
              layout: fb0d,424x87,0,0{205x87,0,0,0,218x87,206,0,4}
              root: ~/workspace/github.com
              panes:
                  - sleep 1; clear
                  - sleep 1; clear
          - codetwo:
              layout: fb0d,424x87,0,0{205x87,0,0,0,218x87,206,0,4}
              root: ~/workspace/github.com
              panes:
                  - sleep 1; clear
                  - sleep 1; clear
          - codethree:
              layout: fb0d,424x87,0,0{205x87,0,0,0,218x87,206,0,4}
              root: ~/workspace/github.com
              panes:
                  - sleep 1; clear
                  - sleep 1; clear
          - shell:
              layout: bac0,484x93,0,0[484x35,0,0{242x35,0,0,3,120x35,243,0,8,120x35,364,0[120x17,364,0,9,120x17,364,18,10]},484x36,0,36,11,484x20,0,73,14]
              root: ~/
              panes:
                  - sleep 1; clear;
                  - sleep 2; clear;
                  - sleep 2; clear;
                  - sleep 2; clear;
                  - sleep 1; clear;
                  - sleep 1; clear;
          - kb:
              layout: fb0d,424x87,0,0{205x87,0,0,0,218x87,206,0,4}
              root: ~/workspace/github.com/curtbushko/kb
              panes:
                  - clear;
        '';
      };
    };
  };
}
