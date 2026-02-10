{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.terminals;
  colors = lib.importJSON ../../home/styles/${config.curtbushko.theme.name}.json;
in {
  config = mkIf cfg.enable {
    stylix.targets.tmux.enable = true;
    programs.tmux = {
      enable = true;
      package = pkgs.tmux.overrideAttrs (oldAttrs: rec {
        version = "3.5a";
        src = pkgs.fetchFromGitHub {
          owner = "tmux";
          repo = "tmux";
          rev = version;
          hash = "sha256-Z9XHpyh4Y6iBI4+SfFBCGA8huFJpRFZy9nEB7+WQVJE=";
        };
      });
      terminal = "xterm-ghostty";
      tmuxinator.enable = true;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        yank
      ];
      newSession = true;
      sensibleOnTop = false;
      disableConfirmationPrompt = true;
      extraConfig = let
        active = "${colors.teal}";
        inactive = "#6C7086";
        background = "${colors.bg_dark}";
        foreground = "${colors.blue0}";
      in ''
        # fix tmux not showing italics in neovim
        # to test, do: echo -e "\e[3mThis text should be italic\e[0m"
        # Update display variables when attaching to a session
        set -g update-environment "DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
        set -g default-terminal "tmux-256color"
        set -ag terminal-features ",tmux-256color:RGB"
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

        # Zellij-style keybindings
        # New panes
        bind-key -n M-n split-window -h -c "#{pane_current_path}"
        bind-key -n M-m split-window -v -c "#{pane_current_path}"

        # Pane navigation
        bind-key -n M-h select-pane -L
        bind-key -n M-l select-pane -R
        bind-key -n M-j select-pane -D
        bind-key -n M-k select-pane -U
        bind-key -n M-Left select-pane -L
        bind-key -n M-Right select-pane -R
        bind-key -n M-Down select-pane -D
        bind-key -n M-Up select-pane -U
        # Pane resize
        bind-key -n M-= resize-pane -U 2
        bind-key -n M-- resize-pane -D 2
        # Tab/window navigation
        bind-key -n M-1 select-window -t 1
        bind-key -n M-2 select-window -t 2
        bind-key -n M-3 select-window -t 3
        bind-key -n M-4 select-window -t 4
        bind-key -n M-5 select-window -t 5
        bind-key -n M-6 select-window -t 6
        bind-key -n M-7 select-window -t 7
        bind-key -n M-8 select-window -t 8
        bind-key -n M-9 select-window -t 9
        # Vim-style tab navigation
        #bind-key -n M-K select-window -p
        #bind-key -n M-J select-window -n
        #bind-key -n M-h select-window -p
        #bind-key -n M-l select-window -n
        bind-key -n M-h if-shell -F "#{pane_at_left}" "select-window -p" "select-pane -L"
        bind-key -n M-j if-shell -F "#{pane_at_bottom}" "select-window -p" "select-pane -D"
        bind-key -n M-k if-shell -F "#{pane_at_top}" "select-window -n" "select-pane -U"
        bind-key -n M-l if-shell -F "#{pane_at_right}" "select-window -n" "select-pane -R"
        # Toggle floating (zoom equivalent)
        bind-key -n M-p resize-pane -Z
        # Detach session (matches zellij Ctrl+d)
        bind-key -n C-d detach-client

        set -g status-left '#[fg=${inactive},bg=${background}]      '
        set -g status-right ' '
        set-option -g status-position top 
        set -g status-style 'fg=${inactive},bg=${background}'
        set -g status-left-style 'fg=${inactive},bg=${background}'
        set -g status-right-style 'fg=${inactive},bg=${background}'
        set -g status-bg '${background}'
        set -g status-fg '${inactive}'
        set -g pane-border-style 'bg=${background},fg=${inactive}'
        set -g pane-active-border-style 'bg=${background},fg=${active},bold'
        set -g display-panes-colour '${inactive}'
        set -g display-panes-active-colour '${active}'
        # Window status styling to match zellij
        set-window-option -g window-status-format '#[fg=${inactive},bg=${background}]#W'
        set-window-option -g window-status-current-format '#[fg=${active},bg=${background}]#W'
        set-window-option -g window-status-current-style 'fg=${active},bg=${background}'
        set-window-option -g window-status-last-style 'fg=${active},bg=${background}'
        set-window-option -g window-status-separator '  '
      '';
    };

    home.file = {
      ".config/tmuxinator/home.yml" = {
        text = ''
          name: home
          startup_window: "󰎦"
          root: ~/
          windows:
          - "󰎦":
              root: ~/workspace/github.com
              panes:
                  - clear
          - "󰎩":
              root: ~/workspace/github.com
              panes:
                  - clear
          - "󰎬":
              root: ~/workspace/github.com
              panes:
                  - clear
          - "󰎮":
              root: ~/workspace/github.com
              panes:
                  - clear
          - "󰎰":
              root: ~/workspace/github.com
              panes:
                  - clear
        '';
      };
    };
  };
}
