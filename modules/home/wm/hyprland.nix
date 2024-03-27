{
  pkgs,
  lib,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    #nvidia = true;
    settings = {
      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      #"$menu" = "nwg-drawer";

      "$rosewater" = "0xfff5e0dc";
      "$red" = "0xfff38ba8";
      "$surface1" = "0xff45475a";
      "$surface0" = "0xff313244";

      #monitor = [
      #  "desc:Samsung Display Corp. 0x4165,preferred,0x0,2.5"
      #  "desc:Dell Inc. DELL U2414H H8H7G57B3JJS,1920x1080,1536x-400,1,transform,1"
      #  "desc:Dell Inc. DELL U2414H H8H7G57B3JHS,preferred,2616x0,1"
      #];
      dwindle = {
        preserve_split = true;
      };
      bind = [
        "$mainMod, Return, exec, $terminal"
        "$mainMod SHIFT, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, Space, togglefloating,"
        #"$mainMod, D, exec, $menu"
        "$mainMod, P, pseudo, # dwindle"
        "$mainMod, R, togglesplit, # dwindle"
        #"$mainMod CTRL, P, exec, ${./scripts/wofi-pass.sh}"
        #"$mainMod SHIFT, G, exec, ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area"

        "$mainMod, F, fullscreen"
        "$mainMod, E, togglegroup"

        "$mainMod, H, movefocus, l"
        "$mainMod, J, movefocus, d"
        "$mainMod, K, movefocus, u"
        "$mainMod, L, movefocus, r"

        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, J, movewindow, d"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod SHIFT, L, movewindow, r"

        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      misc = {
        force_default_wallpaper = 0;
      };
      decoration = {
        inactive_opacity = 0.9;
        rounding = 5;
        dim_inactive = true;
        dim_strength = 0.2;
      };
      animations = {
        enabled = false;
        # enabled = true;
        bezier = "easeInOutQuad, 0.45, 0, 0.55, 1";

        animation = [
          "windows, 1, 1, easeInOutQuad, slide"
          # "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          # "borderangle, 1, 8, default"
          # "fade, 1, 7, default"
          # "workspaces, 1, 6, default"
          "workspaces, 1, 1, easeInOutQuad, slide"
        ];
      };
      input = {
        repeat_delay = 250;
      };
      general = {
        "col.active_border" = "$red";
        "col.inactive_border" = "$surface1 $surface0 45deg";
        border_size = 5;
        gaps_out = 5;
      };
      # opengl.nvidia_anti_flicker = 0;
    };
    # systemd.enable = false;
  };
}
