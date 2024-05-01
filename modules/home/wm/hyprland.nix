{
  pkgs,
  lib,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  #screenOffCmd = ''swaymsg "output * dpms off"'';
  #suspendCmd = ''swaymsg "output * dpms on"; sleep 2; suspend-script'';
  #hibernateCmd = ''swaymsg "output * dpms on"; sleep 2; hybernate-script'';
  #resumeCmd = ''swaymsg "output * dpms on"'';
  wallpaperCmd = "${pkgs.hyprpaper}/bin/hyprpaper";
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
      "$terminal" = "ghostty";
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
        wallpaperCmd
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
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
        gaps_in = 10;
        gaps_out = 10;
        border_size = 1;

        "col.inactive_border" = "$border-color";
        "col.active_border" = "$active-border-color";
        "no_border_on_floating" = false;
        #layout = "master";
        layout = "diwndle";
        no_cursor_warps = true;
      };
      bind = [
        "$super, M, exit,"

        # Most used applications
        "$super, t, exec, $terminal"
        "$super, w, exec, $browser"
        #"$alt, f, exec, $filemanager"
        "$super, Return, exec, $terminal"
        "$super, Q, killactive,"
        "$super, Space, exec, rofi -show drun"
        #"$alt, D, exec, $menu"
        #"$super, P, pseudo, # dwindle"
        #"$super, R, togglesplit, # dwindle"
        #"$alt CTRL, P, exec, ${./scripts/wofi-pass.sh}"
        #"$alt SHIFT, G, exec, ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area"

        "$alt $super, F, fullscreen"
        "$super, E, togglegroup"

        # Change app focus around
        "$super, $left, movefocus, l"
        "$super, $down, movefocus, d"
        "$super, $up, movefocus, u"
        "$super, $right, movefocus, r"
        # Or use arrow keys
        "$super, left, movefocus, l"
        "$super, down, movefocus, d"
        "$super, up, movefocus, u"
        "$super, right, movefocus, r"

        # Cycle windows
        "$super, tab, layoutmsg, cyclenext"
        "$super SHIFT, tab, layoutmsg, cyclenext, prev"

        # Move the focused window
        "$super $alt, $left, movewindow, l"
        "$super $alt, $down, movewindow, d"
        "$super $alt, $up, movewindow, u"
        "$super $alt, $right, movewindow, r"
        # Or use arrow keys
        "$super $alt, left, movewindow, l"
        "$super $alt, down, movewindow, d"
        "$super $alt, up, movewindow, u"
        "$super $alt, right, movewindow, r"

        "$super, 1, workspace, 1"
        "$super, 2, workspace, 2"
        "$super, 3, workspace, 3"
        "$super, 4, workspace, 4"
        "$super, 5, workspace, 5"
        "$super, 6, workspace, 6"
        "$super, 7, workspace, 7"
        "$super, 8, workspace, 8"
        "$super, 9, workspace, 9"
        "$super, 0, workspace, 10"

        # Move window to workspace
        "$super CTRL, 1, movetoworkspace, 1"
        "$super CTRL, 2, movetoworkspace, 2"
        "$super CTRL, 3, movetoworkspace, 3"
        "$super CTRL, 4, movetoworkspace, 4"
        "$super CTRL, 5, movetoworkspace, 5"
        "$super CTRL, 6, movetoworkspace, 6"
        "$super CTRL, 7, movetoworkspace, 7"
        "$super CTRL, 8, movetoworkspace, 8"
        "$super CTRL, 9, movetoworkspace, 9"
        "$super CTRL, 0, movetoworkspace, 10"

        "$super, S, togglespecialworkspace, magic"
        "$super SHIFT, S, movetoworkspace, special:magic"

        "$super, mouse_down, workspace, e+1"
        "$super, mouse_up, workspace, e-1"

        # Resize like Rectangle (you must double dispatch to move and resize at the same time)
        # First 3/4
        "$super $alt, 1, movewindow, l"
        "$super $alt, 1, resizeactive, exact 70% 100%"
        # Last 1/4
        "$super $alt, 2, movewindow, r"
        "$super $alt, 2, resizeactive, exact 30% 100%"
        # First 2/3
        "$super $alt, 3, movewindow, l"
        "$super $alt, 3, resizeactive, exact 66% 100%"
        # Last 1/3
        "$super $alt, 4, movewindow, r"
        "$super $alt, 4, resizeactive, exact 33% 100%"
      ];
      bindm = [
        "$super, mouse:272, movewindow"
        "$super, mouse:273, resizewindow"
      ];
      misc = {
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
        allow_session_lock_restore = true;
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
        force_split = 2;  #forces split to the right
        preserve_split = true;
        use_active_for_splits = true;
      };
      #master = {
      #  orientation = "right";
      #  new_is_master = false;
      #};
      input = {
        repeat_delay = 250;
      };
      windowrulev2 = [
        "move 2288 44, class:(firefox)"
        "size 1146 1390, class:(firefox)"
        "move 6 44, class:(com.mitchellh.ghostty)"
        "size 2270 1390, class:(com.mitchellh.ghostty)"
        "float,class:^(org.kde.polkit-kde-authentication-agent-1)$"
        "float,class:^(pavucontrol)$"
        "float,title:^(Media viewer)$"
        "float,title:^(Volume Control)$"
        "float,class:^(Viewnior)$"
        "float,title:^(DevTools)$"
        "float,class:^(file_progress)$"
        "float,class:^(confirm)$"
        "float,class:^(dialog)$"
        "float,class:^(download)$"
        "float,class:^(notification)$"
        "float,class:^(error)$"
        "float,class:^(confirmreset)$"
        "float,title:^(Open File)$"
        "float,title:^(branchdialog)$"
        "float,title:^(Confirm to replace files)$"
        "float,title:^(File Operation Progress)$"
      ];
    };
    # systemd.enable = false;
  };
}
