{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm;
  isLinux = pkgs.stdenv.isLinux;
  colors = import ../styles/rebel-scum.nix {};
in {
  config = mkIf cfg.enable {
    stylix.targets.hyprland.enable = false;
    wayland.windowManager.hyprland = {
      enable = isLinux;
      systemd.enable = true;
      systemd.variables = ["--all"];
      #nvidia = true;
      settings = {
        # CTRL = Desktop
        "$ctrl" = "CTRL";
        # Alt = App (like zellij tabs)
        "$alt" = "ALT";
        # Super = window
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
        #"$border-color" = "rgb(1A1B26)";
        "$border-color" = "rgba(${builtins.substring 1 6 (colors.statusline_a_fg)}ff)";
        #"$active-border-color" = "rgb(00b0fc)";
        "$active-border-color" = "rgba(${builtins.substring 1 6 (colors.statusline_a_bg)}ff)";
        #"$bg-color" = "rgb(1A1B26)";
        "$bg-color" =  "rgba(${builtins.substring 1 6 (colors.bg)}ff)";
        #"$inac-bg-color" = "rgb(1A1B26)";
        "$inac-bg-color" =  "rgba(${builtins.substring 1 6 (colors.bg)}ff)";
        #"$text-color" = "rgb(F7768E)";
        "$text-color" =  "rgba(${builtins.substring 1 6 (colors.fg)}ff)";
        #"$inac-text-color" = "rgb(A9B1D6)";
        "$inac-text-color" =  "rgba(${builtins.substring 1 6 (colors.fg_dark)}ff)";
        #$"$urgent-bg-color" = "rgb(F7768E)";
        "$urgent-bg-color" =  "rgba(${builtins.substring 1 6 (colors.red1)}ff)";
        #"$indi-color" = "rgb(7AA2F7)";
        "$indi-color" =  "rgba(${builtins.substring 1 6 (colors.blue)}ff)";
        #"$urgent-text-color" = "rgb(A9B1D6)";
        "$urgent-text-color" =  "rgba(${builtins.substring 1 6 (colors.fg_dark)}ff)";

        env = [
          "QT_QPA_PLATFORM,wayland"
          "QT_QPA_PLATFORMTHEME,qt5ct"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        ];
        exec-once = [
          #wallpaperCmd
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
            #"desc:Dell Inc. DELL ULTRASHARP U3219W,3440x1440@60,auto,1"
            "DP-2,3440x1440@60,auto,1"
            #"desc:Dell Inc. DELL S2721QS 93DPZY3,3840x2160@60,auto-right,1,transform,3"
            "HDMI-A-1,3840x2160@60,auto-up,1.2"
            # 2024.07.06 - work around a kernel bug with phantom monitors
            #"dest:Unknown-1,disabled"
          ];
          workspace = [
            "1, monitor:DP-2, default:true"
            "2, monitor:DP-2"
            "3, monitor:DP-2"
            "4, monitor:DP-2"
            "5, monitor:DP-2"
            "6, monitor:HDMI-A-1, default=true"
            "7, monitor:HDMI-A-1"
            "8, monitor:HDMI-A-1"
            "9, monitor:HDMI-A-1"
            "10, monitor:HDMI-A-1"
          ];
          gaps_in = 10;
          gaps_out = 10;
          border_size = 1;

          "col.inactive_border" = "$border-color";
          "col.active_border" = "$active-border-color";
          "no_border_on_floating" = false;
          layout = "master";
          #no_cursor_warps = true;
        };
        debug = {
          colored_stdout_logs = true;
          disable_logs = false;
          enable_stdout_logs = true;
        };
        bind = [
          "$super, M, exit,"

          # Most used applications
          #"$super, t, exec, $terminal"
          #"$super, w, exec, $browser"
          #"$alt, f, exec, $filemanager"
          "$super, Return, exec, $terminal"
          "$super, Q, killactive,"
          "$super, Space, exec, rofi -show drun"
          #"$alt, D, exec, $menu"
          #"$super, P, pseudo, # dwindle"
          #"$super, R, togglesplit, # dwindle"
          #"$alt CTRL, P, exec, ${./scripts/wofi-pass.sh}"
          #"$alt SHIFT, G, exec, ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area"

          # Paste using rofi
          "super, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

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
          "$super $ctrl, $left, movewindow, l"
          "$super $ctrl, $down, movewindow, d"
          "$super $ctrl, $up, movewindow, u"
          "$super $ctrl, $right, movewindow, r"
          # Or use arrow keys
          "$super $ctrl, left, movewindow, l"
          "$super $ctrl, down, movewindow, d"
          "$super $ctrl, up, movewindow, u"
          "$super $ctrl, right, movewindow, r"

          "$ctrl, 1, workspace, 1"
          "$ctrl, 2, workspace, 2"
          "$ctrl, 3, workspace, 3"
          "$ctrl, 4, workspace, 4"
          "$ctrl, 5, workspace, 5"
          "$ctrl, 6, workspace, 6"
          "$ctrl, 7, workspace, 7"
          "$ctrl, 8, workspace, 8"
          "$ctrl, 9, workspace, 9"
          "$ctrl, 0, workspace, 10"

          "$ctrl, H, workspace, -1"
          "$ctrl, L, workspace, +1"

          # Move window to workspace
          "$super $ctrl, 1, movetoworkspace, 1"
          "$super $ctrl, 2, movetoworkspace, 2"
          "$super $ctrl, 3, movetoworkspace, 3"
          "$super $ctrl, 4, movetoworkspace, 4"
          "$super $ctrl, 5, movetoworkspace, 5"
          "$super $ctrl, 6, movetoworkspace, 6"
          "$super $ctrl, 7, movetoworkspace, 7"
          "$super $ctrl, 8, movetoworkspace, 8"
          "$super $ctrl, 9, movetoworkspace, 9"
          "$super $ctrl, 0, movetoworkspace, 10"

          "$super, S, togglespecialworkspace, magic"
          "$super SHIFT, S, movetoworkspace, special:magic"

          "$super, mouse_down, workspace, e+1"
          "$super, mouse_up, workspace, e-1"

          # Resize like Rectangle (you must double dispatch to move and resize at the same time)
          "$alt $super, F, fullscreen"
          # First 3/4
          "$super $alt, 1, exec, hyprctl dispatcher splitratio exact 0.75"
          "$super $alt, 2, exec, hyprctl dispatcher splitratio exact 0.75"
          # First 2/3
          "$super $alt, 3, exec, hyprctl dispatcher splitratio exact 0.66"
          "$super $alt, 4, exec, hyprctl dispatcher splitratio exact 0.66"

          "$super alt, p, pin"

          "$super $alt, h, resizeactive, -40 0"
          "$super $alt, -, resizeactive, -40 0"
          "$super $alt, l, resizeactive, 40 0"
          "$super $alt, =, resizeactive, 40 0"
          "$super $alt, k, resizeactive, 0 -40"
          "$super $alt, j, resizeactive, 0 40"
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
          background_color = "rgba(${builtins.substring 1 6 (colors.statusline_c_bg)}ff)";
        };
        decoration = {
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
          blurls = ["lockscreen" "popups"];
          dim_inactive = true;
          dim_strength = "0.1";
          fullscreen_opacity = 1;
          rounding = 1;
          shadow = {
            enabled = true;
            ignore_window = true;
            offset = "0 8";
            range = 50;
            render_power = 3;
            color = "rgba(00000055)";
          };
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
        #dwindle = {
        #  no_gaps_when_only = false;
        #pseudotile = true;
        #  force_split = 2;  #forces split to the right
        #preserve_split = true;
        #  use_active_for_splits = true;
        #};
        master = {
          orientation = "left";
          #new_is_master = false;
          new_on_top = true;
          special_scale_factor = 0.4;
        };
        input = {
          repeat_delay = 250;
        };
        windowrulev2 = [
          #"float,class:(firefox)"
          "size 1148 1380,class:(firefox)"
          # Make sure nvim is always in these workspaces
          #"workspace 1,class:(com.mitchellh.ghostty)"
          #"workspace 2,class:(com.mitchellh.ghostty)"
          #"workspace 3,class:(com.mitchellh.ghostty)"
          "pin,class:(com.mitchellh.ghostty)"
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
  };
}
