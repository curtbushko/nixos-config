{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.wm.niri;
  colors = lib.importJSON ../styles/${config.curtbushko.theme.name}.json;

  # Wallpaper SHA256 hashes
  wallpaperHashes = {
    "firewatch-green.jpg" = "sha256-ILiIAcw9JMHsRNT63TnR3kn1O4IwEliJtb2FwdIQUEM=";
    "cyberpunk-tokyo.png" = lib.fakeHash;
    "cyberpunk_2077_phantom_liberty_katana.jpg" = lib.fakeHash;
    "green-pasture.jpg" = lib.fakeHash;
    "cyberpunk-three.png" = lib.fakeHash;
  };

  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/curtbushko/nixos-wallpapers/main/3440x1440/${config.curtbushko.theme.wallpaper}";
    sha256 = wallpaperHashes.${config.curtbushko.theme.wallpaper} or lib.fakeHash;
  };
in {
  options.curtbushko.wm.niri = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable niri
      '';
    };
  };
  imports = [inputs.niri.homeModules.niri];

  config = mkIf cfg.enable {
    home.sessionVariables = {
      WAYLAND_DISPLAY = "wayland-1";
    };

    home.packages = with pkgs;
    [
      alacritty
      niri
      swaybg
      swayidle
      xwayland-satellite
      playerctl
    ];

    # Run niri as a service so that other services start (ie swayidle)
    systemd.user.services.niri = {
        Unit = {
          Description = "A scrollable-tiling Wayland compositor";
          BindsTo = "graphical-session.target";
          Before = "graphical-session.target";
          Wants = "graphical-session-pre.target";
          After = "graphical-session-pre.target";
        };
        Service = {
          Slice = "session.slice";
          Type = "notify";
          ExecStart = "${pkgs.niri}/bin/niri --session";
        };
    };

    programs.niri = {
      enable = true;
      package = pkgs.niri;
      settings = {
        environment = {
          CLUTTER_BACKEND = "wayland";
          # DISPLAY is managed by niri's built-in xwayland integration
          GDK_BACKEND = "wayland,x11";
          GSK_RENDERER = "ngl"; # 2025-09-16 - seems to be needed for nautilus to work
          MOZ_ENABLE_WAYLAND = "1";
          NIXOS_OZONE_WL = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          SDL_VIDEODRIVER = "wayland";
          WAYLAND_DISPLAY = "wayland-1";
          XDG_CURRENT_DESKTOP = "niri";
          XDG_SESSION_DESKTOP = "niri";
          XDG_SESSION_TYPE = "wayland";
          XCURSOR_THEME = "Adwaita";
          XCURSOR_SIZE = "20";
          # Used for fixing nautilus not closing
          GTK_IM_MODULE = "wayland";
          QT_IM_MODULE = "wayland";
        };
        spawn-at-startup = [
          { command = [ "systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" ]; }
          { command = [ "wl-paste --type text --watch cliphist store" ]; }
          { command = [ "wl-paste --type image --watch cliphist store" ]; }
          # xwayland-satellite is managed by niri's built-in integration (since 25.08)
          # niri creates X11 sockets, exports DISPLAY, and spawns xwayland-satellite on demand
        ];
        input = {
          keyboard.xkb.layout = "us";
          focus-follows-mouse.enable = true;
          warp-mouse-to-focus.enable = true;
          workspace-auto-back-and-forth = true;
        }; # input
        screenshot-path = "~/Pictures/Screenshots/Screenshot-from-%Y-%m-%d-%H-%M-%S.png";

        outputs = {
          "DP-2" = {
            focus-at-startup = true;
            mode = {
              width = 3440;
              height = 1440;
            };
            scale = 1.0;
            position = {
              x = 0;
              y = 1800;
            };
          };
          "HDMI-A-1" = {
            mode = {
              width = 3840;
              height = 2160;
            };
            scale = 1.2;
            position = {
              x = 0;
              y = 0;
            };
          };
        }; # outputs
        cursor = {
          size = 20;
        };
        layout = {
          focus-ring.enable = false;
          border = {
            enable = true;
            width = 1;
            active.color = "${colors.statusline_a_bg}";
            inactive.color = "${colors.statusline_b_bg}";
          };
          shadow = {
            enable = true;
          };
          preset-column-widths = [
            {proportion = 0.33333;}
            {proportion = 0.5;}
            {proportion = 0.66667;}
          ];
          default-column-width = {proportion = 0.33333;};

          preset-window-heights = [
            {proportion = 0.33333;}
            {proportion = 0.5;}
            {proportion = 0.66667;}
          ];

          gaps = 15;
          struts = {
            left = 8;
            right = 8;
            top = 8;
            bottom = 8;
          };

          tab-indicator = {
            hide-when-single-tab = true;
            place-within-column = true;
            position = "left";
            corner-radius = 20.0;
            gap = -12.0;
            gaps-between-tabs = 10.0;
            width = 4.0;
            length.total-proportion = 0.1;
          };
        }; # layout

        animations.window-resize.custom-shader = ''
          vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
            vec3 coords_next_geo = niri_curr_geo_to_next_geo * coords_curr_geo;

            vec3 coords_stretch = niri_geo_to_tex_next * coords_curr_geo;
            vec3 coords_crop = niri_geo_to_tex_next * coords_next_geo;

            // We can crop if the current window size is smaller than the next window
            // size. One way to tell is by comparing to 1.0 the X and Y scaling
            // coefficients in the current-to-next transformation matrix.
            bool can_crop_by_x = niri_curr_geo_to_next_geo[0][0] <= 1.0;
            bool can_crop_by_y = niri_curr_geo_to_next_geo[1][1] <= 1.0;

            vec3 coords = coords_stretch;
            if (can_crop_by_x)
                coords.x = coords_crop.x;
            if (can_crop_by_y)
                coords.y = coords_crop.y;

            vec4 color = texture2D(niri_tex_next, coords.st);

            // However, when we crop, we also want to crop out anything outside the
            // current geometry. This is because the area of the shader is unspecified
            // and usually bigger than the current geometry, so if we don't fill pixels
            // outside with transparency, the texture will leak out.
            //
            // When stretching, this is not an issue because the area outside will
            // correspond to client-side decoration shadows, which are already supposed
            // to be outside.
            if (can_crop_by_x && (coords_curr_geo.x < 0.0 || 1.0 < coords_curr_geo.x))
                color = vec4(0.0);
            if (can_crop_by_y && (coords_curr_geo.y < 0.0 || 1.0 < coords_curr_geo.y))
                color = vec4(0.0);

            return color;
          }
        '';
        prefer-no-csd = true;
        hotkey-overlay.skip-at-startup = true;

        window-rules = [
          {
            geometry-corner-radius =
              let
                radius = 4.0;
              in
              {
                bottom-left = radius;
                bottom-right = radius;
                top-left = radius;
                top-right = radius;
              };
            clip-to-geometry = true;
          }
          # Block sensitive windows from screencasts
          {
            matches = [
              { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
              { app-id = "^org\\.gnome\\.World\\.Secrets$"; }
            ];
            block-out-from = "screencast";
          }
          # Highlight windows being screencasted
          {
            matches = [
              { is-window-cast-target = true; }
            ];
            focus-ring = {
              enable = true;
              active.color = "#f38ba8";
              inactive.color = "#7d0d2d";
            };
            border = {
              enable = true;
              inactive.color = "#7d0d2d";
            };
            shadow = {
              color = "#7d0d2d70";
            };
          }
          {
            matches = [
              {
                app-id = "(mpv)";
              }
            ];
            open-on-output = "HDMI-A-1";
            open-maximized = true;
            open-fullscreen = false;
          }
          {
            matches = [
              {
                app-id = "(obsidian)";
              }
            ];
            default-column-width.proportion = 4.0 / 10.0;
          }
          {
            matches = [
              {
                app-id = "com.mitchellh.ghostty";
              }
            ];
            draw-border-with-background = false;
            open-focused = true;
          }
          {
            matches = [
              {
                  app-id = "^(zen|firefox|chromium-browser|edge|chrome-.*|zen-.*)$";
              }
            ];
            default-column-width.proportion = 0.33;
          }
          {
            matches = [
              {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              }
              {
                app-id = "zen-.*$";
                title = "^Picture-in-Picture$";
              }
              {  title = "^Picture in picture$";}
              {  title = "^Discord Popout$";}
              {  title = "^floating$";}
            ];
            open-floating = true;
            default-floating-position = {
              x = 32;
              y = 32;
              relative-to = "top-right";
            };
          }
        ];

        binds = let
          inherit (config.lib.niri) actions;
        in
        {
          "Mod+Return".action.spawn = "ghostty";
          "Mod+T".action.spawn = "ghostty";
          "Mod+Space".action.spawn = ["vicinae" "vicinae://toggle"]; # fuzzel
          "Mod+V".action.spawn = ["vicinae" "vicinae://extensions/vicinae/clipboard/history"];
          "Mod+Tab".action = actions.toggle-overview;

          "Mod+Shift+Slash".action = actions.show-hotkey-overlay;
          "Mod+Q".action = actions.close-window;
          "Mod+M".action = actions.quit;
          "Ctrl+Alt+Delete".action = actions.quit;

          "Mod+Left".action = actions.focus-column-left;
          "Mod+Down".action = actions.focus-window-or-monitor-down;
          "Mod+Up".action = actions.focus-window-or-monitor-up;
          "Mod+Right".action = actions.focus-column-right;
          "Mod+H".action = actions.focus-column-left;
          "Mod+J".action = actions.focus-window-or-monitor-down;
          "Mod+K".action = actions.focus-window-or-monitor-up;
          "Mod+L".action = actions.focus-column-right;

          "Mod+Ctrl+Left".action = actions.move-column-left;
          "Mod+Ctrl+Down".action = actions.move-window-down;
          "Mod+Ctrl+Up".action =actions.move-window-up;
          "Mod+Ctrl+Right".action = actions.move-column-right;
          "Mod+Ctrl+H".action = actions.move-column-left;
          "Mod+Ctrl+J".action = actions.move-column-to-monitor-down;
          "Mod+Ctrl+K".action = actions.move-column-to-monitor-up;
          "Mod+Ctrl+L".action = actions.move-column-right;
  
          "Ctrl+J".action = actions.focus-workspace-down;
          "Ctrl+K".action = actions.focus-workspace-up;

          "Mod+Shift+Minus".action = actions.set-window-width "-10%";
          "Mod+Shift+Equal".action = actions.set-window-width "+10%";

          # Sizing
          "Mod+Alt+F".action = actions.fullscreen-window;
          "Mod+Alt+Right".action = actions.switch-preset-column-width;
          "Mod+Alt+Left".action = actions.switch-preset-column-width;
          "Mod+Alt+H".action = actions.switch-preset-column-width;
          "Mod+Alt+L".action = actions.switch-preset-column-width;
          "Mod+Alt+Up".action = actions.switch-preset-window-height;
          "Mod+Alt+Down".action = actions.switch-preset-window-height;

          # Volume keys mappings for PipeWire & WirePlumber.
          XF86AudioRaiseVolume.action = actions.spawn [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "+2dB" ];
          XF86AudioLowerVolume.action = actions.spawn [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "-2dB" ];
          XF86AudioMute.action = actions.spawn [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
          XF86AudioMicMute.action = actions.spawn [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
          XF86AudioNext.action = actions.spawn [ "playerctl" "next" ];
          XF86AudioPrev.action = actions.spawn [ "playerctl" "previous" ];
          XF86AudioPlay.action = actions.spawn [ "playerctl" "play-pause" ];
          XF86AudioStop.action = actions.spawn [ "playerctl" "play-pause" ];

        }; # binds
      }; # settings
    }; # programs.niri

    services.polkit-gnome.enable = true;

    # e.g. for slack, etc
    xdg.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
    '';

    xdg.portal = {
      enable = true;
      config = {
        common = {
          default = [ "gnome" ];
          "org.freedesktop.impl.portal.Settings" = [ "gnome" ];
        };
        niri = {
          default = [ "gnome" ];
          "org.freedesktop.impl.portal.Settings" = [ "gnome" ];
        };
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
      ];
      xdgOpenUsePortal = true;
    };

    stylix.targets.fuzzel.enable = false;
    programs.fuzzel = {
      enable = false;
      settings = {
        main = {
          terminal = "ghostty";
          layer = "overlay";
          dpi-aware = "yes";
        };

        colors = with config.lib.stylix.colors; {
          background = "${base00-hex}ff";
          text = "${base05-hex}ff";
          placeholder = "${base03-hex}ff";
          prompt = "${base05-hex}ff";
          input = "${base05-hex}ff";
          match = "${base0B-hex}ff";
          selection = "${base03-hex}ff";
          selection-text = "${base01-hex}ff";
          selection-match = "${base07-hex}ff";
          counter = "${base06-hex}ff";
          border = "${base0D-hex}ff";
        };
        border = {
          width = 2;
        };
      };
    };
  };
}

