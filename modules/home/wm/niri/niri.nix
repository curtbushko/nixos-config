{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.wm.niri;

  makeCommand = command: {
    command = [command];
  };
  colors = import ../../styles/${config.curtbushko.theme.name}.nix {};
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
    home.packages = with pkgs;
    [
      niri
    ];
    programs.niri = {
      enable = true;
      package = pkgs.niri;
      settings = {
        environment = {
          CLUTTER_BACKEND = "wayland";
          DISPLAY = null;
          GDK_BACKEND = "wayland,x11";
          MOZ_ENABLE_WAYLAND = "1";
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          SDL_VIDEODRIVER = "wayland";
        };
        spawn-at-startup = [
          (makeCommand "wl-clip-persist --clipboard regular")
          (makeCommand "cliphist")
          (makeCommand "waybar")
          (makeCommand "xwayland-satellite")
          (makeCommand "niri msg action focus-workspace main")
        ];
        input = {
          keyboard.xkb.layout = "us";
          focus-follows-mouse.enable = true;
          warp-mouse-to-focus = true;
          workspace-auto-back-and-forth = true;
        }; # input
        screenshot-path = "~/Pictures/Screenshots/Screenshot-from-%Y-%m-%d-%H-%M-%S.png";

        outputs = {
          "DP-2" = {
            mode = {
              width = 3440;
              height = 1440;
              refresh = 60.0;
            };
            scale = 1.0;
            position = {
              x = 0;
              y = 2160;
            };
          };
          "HDMI-A-1" = {
            mode = {
              width = 3840;
              height = 2160;
            };
            scale = 1.0;
            position = {
              x = 0;
              y = 0;
            };
          };
        }; # outputs
        workspaces = {
          main.open-on-output = "DP-2";
          top.open-on-output = "HDMI-A-1";
        };
        cursor = {
          size = 20;
        };
        layout = {
          focus-ring.enable = false;
          border = {
            enable = true;
            width = 1;
            active.color = "${colors.blue}";
            inactive.color = "${colors.statusline_a_fg}";
          };
          shadow = {
            enable = true;
          };
          preset-column-widths = [
            {proportion = 0.25;}
            {proportion = 0.5;}
            {proportion = 0.75;}
            {proportion = 1.0;}
          ];
          default-column-width = {proportion = 0.5;};

          gaps = 6;
          struts = {
            left = 0;
            right = 0;
            top = 0;
            bottom = 0;
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

        animations.shaders.window-resize = ''
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
          {
            matches = [ { app-id = "(mpv)"; } ];
            open-on-workspace = "top";
          }
          {

            matches = [ { app-id = "(obsidian)"; } ];
            default-column-width.proportion = 4.0 / 10.0;
          }
          {
            matches = [ { app-id = "com.mitchellh.ghostty"; } ];
            draw-border-with-background = false;
          }
        ];

        binds = let
          inherit (config.lib.niri) actions;
        in
        {
          "Mod+Return".action.spawn = "ghostty";
          "Mod+T".action.spawn = "ghostty";
          "Mod+Space".action.spawn = "fuzzel";

          "Mod+Shift+Slash".action = actions.show-hotkey-overlay;
          "Mod+Q".action = actions.close-window;
          "Mod+M".action = actions.quit;
          "Ctrl+Alt+Delete".action = actions.quit;

          "Mod+Left".action = actions.focus-column-left;
          "Mod+Down".action = actions.focus-window-down;
          "Mod+Up".action = actions.focus-window-up;
          "Mod+Right".action = actions.focus-column-right;
          "Mod+H".action = actions.focus-column-left;
          "Mod+J".action = actions.focus-window-down;
          "Mod+K".action = actions.focus-window-up;
          "Mod+L".action = actions.focus-column-right;

          "Mod+Ctrl+Left".action = actions.move-column-left;
          "Mod+Ctrl+Down".action = actions.move-window-down;
          "Mod+Ctrl+Up".action =actions.move-window-up;
          "Mod+Ctrl+Right".action = actions.move-column-right;
          "Mod+Ctrl+H".action = actions.move-column-left;
          "Mod+Ctrl+J".action = actions.move-window-down;
          "Mod+Ctrl+K".action = actions.move-window-up;
          "Mod+Ctrl+L".action = actions.move-column-right;

          "Mod+Shift+Minus".action = actions.set-window-width "-10%";
          "Mod+Shift+Equal".action = actions.set-window-width "+10%";

        }; # binds
      }; # settings
    }; # programs.niri

    stylix.targets.fuzzel.enable = false;
    programs.fuzzel = {
      enable = true;
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
          width = 1;
        };
      };
    };
  };
}

