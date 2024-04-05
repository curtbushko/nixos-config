{
  pkgs,
  lib,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  wayland.windowManager.hyprland = {
    enable = isLinux;
    #nvidia = true;
    settings = {
      "$MOD" = "ALT";
      "$terminal" = "kitty";

      "$rosewater" = "0xfff5e0dc";
      "$red" = "0xfff38ba8";
      "$surface1" = "0xff45475a";
      "$surface0" = "0xff313244";
      env = [
        "QT_QPA_PLATFORM,wayland"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
      ];
      exec-once = [
        #"hyprlock"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 1"
        "waybar"
      ];
      xwayland = {force_zero_scaling = true;};
      general = {
        monitor = [
            "desc:Dell Inc. DELL ULTRASHARP U3219W,3440x1440@60,0x0,1"
        ];
        gaps_in = 5;
        gaps_out = 5;
        border_size = 1;
        "col.active_border" = "$red";
        #"col.active_border" = "rgb(${c.on_primary})";
        "col.inactive_border" = "$surface1 $surface0 45deg";
        #"col.inactive_border" = "rgb(${c.primary});";
        "no_border_on_floating" = false;
        layout = "dwindle";
        no_cursor_warps = true;
      };
      bind = [
        "$MOD, M, exit,"
        "$MOD, Return, exec, $terminal"
        "CTRL, Return, exec, $terminal"
        "$MOD SHIFT, Q, killactive,"
        "$MOD, M, exit,"
        "$MOD, Space, togglefloating,"
        #"$MOD, D, exec, $menu"
        "$MOD, P, pseudo, # dwindle"
        "$MOD, R, togglesplit, # dwindle"
        #"$MOD CTRL, P, exec, ${./scripts/wofi-pass.sh}"
        #"$MOD SHIFT, G, exec, ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area"

        "$MOD, F, fullscreen"
        "$MOD, E, togglegroup"

        "$MOD, H, movefocus, l"
        "$MOD, J, movefocus, d"
        "$MOD, K, movefocus, u"
        "$MOD, L, movefocus, r"

        "$MOD SHIFT, H, movewindow, l"
        "$MOD SHIFT, J, movewindow, d"
        "$MOD SHIFT, K, movewindow, u"
        "$MOD SHIFT, L, movewindow, r"

        "$MOD, 1, workspace, 1"
        "$MOD, 2, workspace, 2"
        "$MOD, 3, workspace, 3"
        "$MOD, 4, workspace, 4"
        "$MOD, 5, workspace, 5"
        "$MOD, 6, workspace, 6"
        "$MOD, 7, workspace, 7"
        "$MOD, 8, workspace, 8"
        "$MOD, 9, workspace, 9"
        "$MOD, 0, workspace, 10"

        "$MOD SHIFT, 1, movetoworkspace, 1"
        "$MOD SHIFT, 2, movetoworkspace, 2"
        "$MOD SHIFT, 3, movetoworkspace, 3"
        "$MOD SHIFT, 4, movetoworkspace, 4"
        "$MOD SHIFT, 5, movetoworkspace, 5"
        "$MOD SHIFT, 6, movetoworkspace, 6"
        "$MOD SHIFT, 7, movetoworkspace, 7"
        "$MOD SHIFT, 8, movetoworkspace, 8"
        "$MOD SHIFT, 9, movetoworkspace, 9"
        "$MOD SHIFT, 0, movetoworkspace, 10"

        "$MOD, S, togglespecialworkspace, magic"
        "$MOD SHIFT, S, movetoworkspace, special:magic"

        "$MOD, mouse_down, workspace, e+1"
        "$MOD, mouse_up, workspace, e-1"
      ];
      bindm = [
        "$MOD, mouse:272, movewindow"
        "$MOD, mouse:273, resizewindow"
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
        dim_strength = "0.3";
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
