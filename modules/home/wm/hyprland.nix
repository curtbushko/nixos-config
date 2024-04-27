{
  pkgs,
  lib,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  screenOffCmd = ''swaymsg "output * dpms off"'';
  suspendCmd = ''swaymsg "output * dpms on"; sleep 1; suspend-script'';
  resumeCmd = ''swaymsg "output * dpms on"'';
in {
  wayland.windowManager.hyprland = {
    enable = isLinux;
    systemd.variables = ["--all"];
    #nvidia = true;
    settings = {
      # Variables
      "$alt" = "ALT";
      "$super" = "SUPER";
      # Vim navigation
      "$left" = "h";
      "$down" = "j";
      "$up" = "k";
      "$right" = "l";
      # Applications
      "$terminal" = "kitty";
      "$browser" = "rofi-firefox-wrapper";

      # Tokyonight Night colors
      "$border-color" = "rgb(A9B1D6)";
      "$active-border-color" = "rgb(7AA2F7)";
      "$bg-color" = "rgb(1A1B26)";
      "$inac-bg-color" = "rgb(1A1B26)";
      "$text-color" = "rgb(F7768E)";
      "$inac-text-color" = "rgb(A9B1D6)";
      "$urgent-bg-color" = "rgb(F7768E)";
      "$indi-color" = "rgb(7AA2F7)";
      "$urgent-text-color" = "rgb(A9B1D6)";

      env = [
        "QT_QPA_PLATFORM,wayland"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
      ];
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 1"
        "waybar"
        "swayidle -w \
            timeout 30 screenOffCmd \
            timeout 60 suspendCmd \
            resume resumeCmd"
      ];
      xwayland = {force_zero_scaling = true;};
      general = {
        monitor = [
          "desc:Dell Inc. DELL ULTRASHARP U3219W,3440x1440@60,0x0,1"
        ];
        gaps_in = 5;
        gaps_out = 5;
        border_size = 1;

        "col.inactive_border" = "$border-color";
        "col.active_border" = "$active-border-color";
        "no_border_on_floating" = false;
        layout = "dwindle";
        no_cursor_warps = true;
      };
      bind = [
        "$alt, M, exit,"

        # Most used applications
        "$alt, t, exec, $terminal"
        "$alt, w, exec, $browser"
        #"$alt, f, exec, $filemanager"
        "$alt, Return, exec, $terminal"
        "$alt SHIFT, Q, killactive,"
        "$alt, Space, exec, rofi -show drun"
        #"$alt, D, exec, $menu"
        "$alt, P, pseudo, # dwindle"
        "$alt, R, togglesplit, # dwindle"
        #"$alt CTRL, P, exec, ${./scripts/wofi-pass.sh}"
        #"$alt SHIFT, G, exec, ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area"

        "$alt $super, F, fullscreen"
        "$alt, E, togglegroup"

        # Change focus around
        "$alt, $left, movefocus, l"
        "$alt, $down, movefocus, d"
        "$alt, $up, movefocus, u"
        "$alt, $right, movefocus, r"
        # Or use arrow keys
        "$alt, left, movefocus, l"
        "$alt, down, movefocus, d"
        "$alt, up, movefocus, u"
        "$alt, right, movefocus, r"

        # Cycle windows
        "$super, tab, cyclenext"
        "$super SHIFT, tab, cyclenext, prev"

        # Move the focused window
        "$alt SHIFT, $left, movewindow, l"
        "$alt SHIFT, $down, movewindow, d"
        "$alt SHIFT, $up, movewindow, u"
        "$alt SHIFT, $right, movewindow, r"
        # Or use arrow keys
        "$alt SHIFT, left, movewindow, l"
        "$alt SHIFT, down, movewindow, d"
        "$alt SHIFT, up, movewindow, u"
        "$alt SHIFT, right, movewindow, r"

        "$alt, 1, workspace, 1"
        "$alt, 2, workspace, 2"
        "$alt, 3, workspace, 3"
        "$alt, 4, workspace, 4"
        "$alt, 5, workspace, 5"
        "$alt, 6, workspace, 6"
        "$alt, 7, workspace, 7"
        "$alt, 8, workspace, 8"
        "$alt, 9, workspace, 9"
        "$alt, 0, workspace, 10"

        # Move window to workspace
        "$alt SHIFT, 1, movetoworkspace, 1"
        "$alt SHIFT, 2, movetoworkspace, 2"
        "$alt SHIFT, 3, movetoworkspace, 3"
        "$alt SHIFT, 4, movetoworkspace, 4"
        "$alt SHIFT, 5, movetoworkspace, 5"
        "$alt SHIFT, 6, movetoworkspace, 6"
        "$alt SHIFT, 7, movetoworkspace, 7"
        "$alt SHIFT, 8, movetoworkspace, 8"
        "$alt SHIFT, 9, movetoworkspace, 9"
        "$alt SHIFT, 0, movetoworkspace, 10"

        "$alt, S, togglespecialworkspace, magic"
        "$alt SHIFT, S, movetoworkspace, special:magic"

        "$alt, mouse_down, workspace, e+1"
        "$alt, mouse_up, workspace, e-1"
      ];
      bindm = [
        "$alt, mouse:272, movewindow"
        "$alt, mouse:273, resizewindow"
      ];
      misc = {
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
      };
      decoration = {
        rounding = 1;
        blur = {
          size = 6;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
          noise = "0.1";
          contrast = "1.1";
          brightness = "1.2";
          xray = true;
        };
        dim_inactive = true;
        dim_strength = "0.1";
        fullscreen_opacity = 1;
        drop_shadow = true;
        shadow_ignore_window = true;
        shadow_offset = "0 8";
        shadow_range = 50;
        shadow_render_power = 3;
        "col.shadow" = "rgba(00000055)";
        blurls = ["lockscreen" "waybar" "popups"];
      };
      animation = {
        bezier = [
          "fluent_decel, 0, 0.2, 0.4, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "easeinoutsine, 0.37, 0, 0.63, 1"
        ];
        animation = [
          "windowsIn, 1, 1.7, easeOutCubic, slide" # window open
          "windowsOut, 1, 1.7, easeOutCubic, slide" # window close
          "windowsMove, 1, 2.5, easeinoutsine, slide" # everything in between, moving, dragging, resizing

          # fading
          "fadeIn, 1, 3, easeOutCubic" # fade in (open) -> layers and windows
          "fadeOut, 1, 3, easeOutCubic" # fade out (close) -> layers and windows
          "fadeSwitch, 1, 5, easeOutCirc" # fade on changing activewindow and its opacity
          "fadeShadow, 1, 5, easeOutCirc" # fade on changing activewindow for shadows
          "fadeDim, 1, 6, fluent_decel" # the easing of the dimming of inactive windows
          "border, 1, 2.7, easeOutCirc" # for animating the border's color switch speed
          "workspaces, 1, 2, fluent_decel, slide" # styles: slide, slidevert, fade, slidefade, slidefadevert
          "specialWorkspace, 1, 3, fluent_decel, slidevert"
        ];
      };
      dwindle = {
        no_gaps_when_only = false;
        pseudotile = true;
        preserve_split = true;
      };
      input = {
        repeat_delay = 250;
      };
      #opengl.nvidia_anti_flicker = 0;
    };
    # systemd.enable = false;
  };
}
