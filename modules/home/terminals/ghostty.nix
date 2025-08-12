{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.terminals;
in {
  config = mkIf cfg.enable {
    xdg.configFile."ghostty/config" = {
      text = let
        base00 = "#${config.lib.stylix.colors.base00}";
        base01 = "#${config.lib.stylix.colors.base01}";
        base02 = "#${config.lib.stylix.colors.base02}";
        base03 = "#${config.lib.stylix.colors.base03}";
        base04 = "#${config.lib.stylix.colors.base04}";
        base05 = "#${config.lib.stylix.colors.base05}";
        base06 = "#${config.lib.stylix.colors.base06}";
        base07 = "#${config.lib.stylix.colors.base07}";
        base08 = "#${config.lib.stylix.colors.base08}";
        base09 = "#${config.lib.stylix.colors.base09}";
        base0A = "#${config.lib.stylix.colors.base0A}";
        base0B = "#${config.lib.stylix.colors.base0B}";
        base0C = "#${config.lib.stylix.colors.base0C}";
        base0D = "#${config.lib.stylix.colors.base0D}";
        base0E = "#${config.lib.stylix.colors.base0E}";
        base0F = "#${config.lib.stylix.colors.base0F}";
        isLinux = pkgs.stdenv.isLinux;
        isDarwin = pkgs.stdenv.isDarwin;
      in ''
        auto-update = off
        font-size = 10
        font-family = Intel One Mono
        font-style = medium
        font-feature = "ss01"
        #adjust-cell-width = 1%
        #adjust-cell-height = 1%
        background-opacity = .95
        background-blur-radius = 20
        macos-non-native-fullscreen = visible-menu
        macos-option-as-alt = left
        macos-titlebar-style = hidden
        gtk-titlebar = false
        mouse-hide-while-typing = true
        shell-integration = zsh
        window-padding-x = 0
        window-padding-y = 0
        window-save-state = always
        confirm-close-surface = false
        #adw-toast = no-clipboard-copy

        # Keybinds to match macOS since this is a VM
        keybind = super+c=copy_to_clipboard
        keybind = super+v=paste_from_clipboard
        keybind = super+equal=increase_font_size:1
        keybind = super+minus=decrease_font_size:1
        keybind = super+zero=reset_font_size
        keybind = super+q=quit
        keybind = super+shift+comma=reload_config
        keybind = super+k=clear_screen
        #keybind = super+n=new_window
        #keybind = super+w=close_surface
        #keybind = super+shift+w=close_window
        #keybind = super+t=new_tab
        #keybind = super+shift+left_bracket=previous_tab
        #keybind = super+shift+right_bracket=next_tab
        #keybind = super+d=new_split:right
        #keybind = super+shift+d=new_split:down
        #keybind = super+right_bracket=goto_split:next
        #keybind = super+left_bracket=goto_split:previous
        # Unbind these keys as they are the default in linux
        keybind = alt+one=unbind
        keybind = alt+two=unbind
        keybind = alt+three=unbind
        keybind = alt+four=unbind
        keybind = alt+five=unbind
        keybind = alt+six=unbind
        keybind = alt+seven=unbind
        keybind = alt+eight=unbind
        keybind = alt+nine=unbind
        # fix for claude-code
        keybind = shift+enter=text:\n
        # foreground (fg/bg)
        foreground = ${base05}
        background = ${base01}
        # black (bg_dark/red)
        palette = 0=${base00}
        palette = 8=${base02}
        # red (red/organge)
        palette = 1=${base08}
        palette = 9=${base09}
        # green (dark3/magenta)
        palette = 2=${base0B}
        palette = 10=${base0F}
        # yellow (
        palette = 3=${base0A}
        palette = 11=${base04}
        # blue
        palette = 4=${base0C}
        palette = 12=${base0D}
        # purple
        palette = 5=${base0E}
        palette = 13=${base03}
        # aqua
        palette = 6=${base0B}
        palette = 14=${base0F}
        # white
        #palette = 7=${base05}
        #palette = 15=${base06}
      ''
      + (lib.optionalString isLinux ''
        window-decoration = true 
      ''
      )
      + (lib.optionalString isDarwin ''
        window-decoration = true
      ''
      );
    };
  };
}
