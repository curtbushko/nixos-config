{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;
in {
  config = mkIf cfg.enable {
    stylix.targets.waybar.enable = false;
    systemd.user.services.waybar = {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Restart = "on-failure";
        ExecStart = "${pkgs.waybar}/bin/waybar";
      };
    };
    programs.waybar = {
      enable = isLinux;
      settings = [
        {
          layer = "top";
          position = "top";
          spacing = "-4";
          mod = "dock";
          height = 24;
          margin-top = 0;
          margin-bottom = 0;
          exclusive = true;
          passthrough = false;
          gtk-layer-shell = true;
          output = ["DP-2" "HDMI-A-1"];
          /*
          ┓ ┏┓┏┓┏┳┓  ┳┳┓┏┓┳┓┳┳┓ ┏┓┏┓
          ┃ ┣ ┣  ┃   ┃┃┃┃┃┃┃┃┃┃ ┣ ┗┓
          ┗┛┗┛┻  ┻   ┛ ┗┗┛┻┛┗┛┗┛┗┛┗┛
          */
          "group/network" = {
            orientation = "horizontal";
            modules = [
              "network"
            ];
          };

          network = {
            format-wifi = "󰤨 {signalStrength}%";
            format-ethernet = "󱘖 {ipaddr}  {bandwidthUpBytes}  {bandwidthDownBytes}";
            tooltip-format = "󱘖 {ipaddr}  {bandwidthUpBytes}  {bandwidthDownBytes}";
            format-linked = "󱘖 {ifname} (No IP)";
            format-disconnected = " Disconnected";
            format-alt = "󰤨 {essid}";
            interval = 5;
          };

          "custom/network-workspaces-separator" = {
            format = "{}    ";
          };

          "niri/workspaces" = {
            all-outputs = false;
            on-click = "activate";
            persistent-workspaces = {
              "DP-2" = [1 2 3 4 5];
              "HDMI-A-1" = [6 7 8 9 10];
            };
            format = "<span font='13'>{icon}</span>";
            format-icons = {
              "1" = " 󰎦 ";
              "2" = " 󰎩 ";
              "3" = " 󰎬 ";
              "4" = " 󰎮 ";
              "5" = " 󰎰 ";
              "6" = " 󰎵 ";
              "7" = " 󰎸 ";
              "8" = " 󰎻 ";
              "9" = " 󰎾 ";
              "10" = " 󰎣 ";
              default = " 󰅘 ";
              active = " 󱗝 ";
            };

          };

          "custom/workspaces-audio-separator" = {
            format = "{}    ";
          };

          pulseaudio = {
            on-click = "pavucontrol-qt";
            format = "{format_source} {icon} {volume}%";
            format-muted = "{format_source} 󰸈";

            format-bluetooth = "{format_source} 󰋋 󰂯 {volume}%";
            format-bluetooth-muted = "{format_source} 󰟎 󰂯";

            format-source = "󰍬";
            format-source-muted = "󰍭";

            format-icons.default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];

            scroll-step = 1;
            smooth-scrolling-threshold = 1;
          };

          "custom/audio-separator" = {
            format = "{}    ";
          };

          modules-left = [
            "group/network"
            "custom/network-workspaces-separator"
            "niri/workspaces"
            "custom/workspaces-audio-separator"
            "pulseaudio"
            "custom/audio-separator"
          ];

          /*
          ┏┓┏┓┳┓┏┳┓┏┓┳┓  ┳┳┓┏┓┳┓┳┳┓ ┏┓┏┓
          ┃ ┣ ┃┃ ┃ ┣ ┣┫  ┃┃┃┃┃┃┃┃┃┃ ┣ ┗┓
          ┗┛┗┛┛┗ ┻ ┗┛┛┗  ┛ ┗┗┛┻┛┗┛┗┛┗┛┗┛
          */

          clock = {
            format = "{:%R}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          "niri/window" = {
            format = "{title}";
            icon = false;
            separate-outputs = true;
            max-length = 90;
            /*
            format = "<span font='10' rise='-4444'>{}</span>";
            */
            rewrite = {
              "(.*) - Mozilla Firefox" = " ";
              "(.*) Discord \\|(.*)" = " ";
              "(.*) Ghostty" = "  ";
              "(.*) Zellij (.*)" = "  ";
              "(.*) Steam (.*)" = "󰓓 ";
            };
            swap-icon-label = true;
          };

          modules-center = [
            "niri/window"
          ];

          /*
          ┳┓┳┏┓┓┏┏┳┓  ┳┳┓┏┓┳┓┳┳┓ ┏┓┏┓
          ┣┫┃┃┓┣┫ ┃   ┃┃┃┃┃┃┃┃┃┃ ┣ ┗┓
          ┛┗┻┗┛┛┗ ┻   ┛ ┗┗┛┻┛┗┛┗┛┗┛┗┛
          */

          "custom/resources-separator" = {
            format = "{}    ";
          };

          "group/resources" = {
            orientation = "horizontal";
            modules = [
              "cpu"
              "memory"
            ];
          };

          cpu = {
            on-click = "coolercontrol";
            interval = 10;
            format = "󰍛 {usage}%";
          };

          memory.format = "󰽘 {}%";

          "custom/resources-temperature-separator" = {
            format = "{}    ";
          };

          "group/temp" = {
            orientation = "horizontal";
            modules = [
              "custom/gpu"
              "temperature"
            ];
          };

          temperature = {
            hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
            format = "󰍛 {temperatureC}°C";
            critical-threshold = 75;
          };

          "custom/gpu" = {
            on-click = "coolercontrol";
            exec = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
            format = " {}°C";
            interval = 10;
          };

          "custom/temperature-system-separator" = {
            format = "{}    ";
          };

          "group/system" = {
            orientation = "horizontal";
            modules = [
              "custom/suspend"
              "clock"
            ];
          };

          "custom/suspend" = {
            format = " {}";
            exec = "echo ; echo  suspend";
            on-click = "systemctl suspend";
            interval = 86400;
            tooltip = false;
          };

          modules-right = [
            "custom/resources-separator"
            "group/resources"
            "custom/resources-temperature-separator"
            "group/temp"
            "custom/temperature-system-separator"
            "group/system"
          ];

          tray = {
            reverse-direction = true;
            spacing = 5;
          };
        }
      ];

      style = let
        # Read colors from flair's style.json in ~/.config/flair/
        # Note: Requires --impure flag for nix build/home-manager switch
        flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

        # Default fallback colors if flair style.json doesn't exist
        defaultColors = {
          "statusline-a-bg" = "#1d2021";
          "statusline-a-fg" = "#d4be98";
          "statusline-b-bg" = "#282828";
          "statusline-b-fg" = "#d4be98";
          "statusline-c-bg" = "#3c3836";
          "statusline-c-fg" = "#a9b665";
          "text-primary" = "#d4be98";
          "surface-bg" = "#1d2021";
          "git-added" = "#a9b665";
          "status-warning" = "#d8a657";
          "git-deleted" = "#ea6962";
        };

        colors = if builtins.pathExists flairStylePath
                 then builtins.fromJSON (builtins.readFile flairStylePath)
                 else defaultColors;
      in
        ''
          /*
              ┏┓┓ ┏┳┓  ┏┓┏┓┓ ┏┓┳┓┏┓
              ┃┃┃┃┃┃┃  ┃ ┃┃┃ ┃┃┣┫┗┓
              ┗┛┗┻┛┛┗  ┗┛┗┛┗┛┗┛┛┗┗┛
          */
          /*
            Number these by section and the bar is setup as:
            [1][2][3]       [3][2][1]  which maps to:
            [network][workspace][audio]   [resources][temperature][system]
          */
          @define-color section_1_fg ${colors."statusline-a-fg"};
          @define-color section_1_bg ${colors."statusline-a-bg"};

          @define-color section_2_fg ${colors."statusline-b-fg"};
          @define-color section_2_bg ${colors."statusline-b-bg"};

          @define-color section_3_fg ${colors."statusline-c-fg"};
          @define-color section_3_bg ${colors."statusline-c-bg"};

          @define-color cursor #afbbe5;

          @define-color foreground ${colors."text-primary"};

          @define-color background ${colors."surface-bg"};

          /* workspace text colors */
          @define-color active_fg  ${colors."statusline-b-fg"};
          @define-color in_use_fg  ${colors."statusline-b-fg"};

          /* updates-widget icon+text colors */
          @define-color updates_green ${colors."git-added"};
          @define-color updates_yellow ${colors."status-warning"};
          @define-color updates_red ${colors."git-deleted"};
          /* tokyo-night colors
          updates_green = "${colors."git-added"}";
          updates_yellow = "${colors."status-warning"}";
          updates_red = "${colors."git-deleted"}";
          */

          /*
              ┏┓┏┓┳┓┏┓┳┓┏┓┓
              ┃┓┣ ┃┃┣ ┣┫┣┫┃
              ┗┛┗┛┛┗┗┛┛┗┛┗┗┛
          */

          * {
              font-family: "Fira Code";
              font-weight: bold;
              font-size: 12px;
              min-height: 0px;
          }

          window#waybar {
              color: @foreground;
              background: transparent;
              padding: 0;
              margin: 0;
          }

          tooltip {
              background: @background;
              color: @foreground;
              border-radius: 5px;
              border-width: 1px;
          }

          /*
              ┓ ┏┏┓┳┓┓┏┓┏┓┏┓┏┓┏┓┏┓┏┓
              ┃┃┃┃┃┣┫┃┫ ┗┓┃┃┣┫┃ ┣ ┗┓
              ┗┻┛┗┛┛┗┛┗┛┗┛┣┛┛┗┗┛┗┛┗┛
          */

          #workspaces {
              padding: 0px 0px;
              margin: 0px 0px;
          }

          #workspaces button label {
              font-size: 12px;
          }

          /* workspace not selected and not empty */
          #workspaces button {
              padding: 0;
              background-color: @section_2_bg;
              color: @in_use_fg;
              margin: 0;
              border: none;
          }

          /* workspace not selected and empty */
          #workspaces button.persistent {
              padding: 0;
              background-color: @section_2_bg;
              color: @in_use_fg;
              margin: 0;
              border: none;
          }

          #workspaces button.empty {
              color: @section_2_fg;
              background-color: @section_2_bg;
          }

          #workspaces button.active {
              color:  @active_fg;
              background-color: @section_2_bg;
          }

          /*
              ┏┓┏┳┓┓┏┏┓┳┓
              ┃┃ ┃ ┣┫┣ ┣┫
              ┗┛ ┻ ┛┗┗┛┛┗
          */

          #clock {
              padding: 1px 5px 0px 5px;
              background: @section_1_bg;
              color: @section_1_fg;
          }

          #niri-window {
              font-weight: bold;
              font-size: 12px;
              padding: 1px 5px 0px 5px;
              opacity: 1;
              background: transparent;
              color: @section_2_fg;
          }

          /*
          #custom-updates.green {
              color: @updates_green;
          }
          */

          #custom-updates.yellow {
              color: @updates_yellow;
          }

          #custom-updates.red {
              color: @updates_red;
          }

          /*
              ┏┓┏┓┳┳┓┳┳┓┏┓┳┓  ┏┓┏┓┳┓┳┓┳┳┓┏┓       ┓  ┳┳┓┏┓┳┓┏┓┳┳┓
              ┃ ┃┃┃┃┃┃┃┃┃┃┃┃  ┃┃┣┫┃┃┃┃┃┃┃┃┓  ┏┓┏┓┏┫  ┃┃┃┣┫┣┫┃┓┃┃┃
              ┗┛┗┛┛ ┗┛ ┗┗┛┛┗  ┣┛┛┗┻┛┻┛┻┛┗┗┛  ┗┻┛┗┗┻  ┛ ┗┛┗┛┗┗┛┻┛┗
          */

          /* inactiv widget modules */
          #cpu, #memory, #mpris, #custom-spotify, #custom-mode, #custom-gpuinfo, #custom-ddcutil,
          /* group "system" widgets */
          #custom-updates, #custom-power, #custom-copyq,
          /* group "temperature" widgets */
          #bluetooth, #pulseaudio, #wireplumber, #network, #custom-ddc_brightness, #custom-screenrecorder,
          /* group "resources" widgets */
          #custom-screenrecorder, #custom-resources, #idle_inhibitor,
          /* group "network" widgets */
          #custom-filemanager, #custom-browser, #custom-terminal, #custom-editor, #custom-obsidian,
          /* groups + custom-appmenu */
          #custom-appmenu, #network, #window, #resources, #temperature, #system {
              padding: 0px 5px;
          }

          /*
              ┳┓┏┓┏┳┓┓ ┏┏┓┳┓┓┏┓
              ┃┃┣  ┃ ┃┃┃┃┃┣┫┃┫
              ┛┗┗┛ ┻ ┗┻┛┗┛┛┗┛┗┛
          */
          #network {
              background: @section_1_bg;
              color: @section_1_fg
          }
          #group-network {
              background: @section_1_bg;
              color: @section_1_fg
          }
          #custom-network-workspaces-separator {
              background: linear-gradient(120deg, @section_1_bg 50%, @section_2_bg 50%);
              color: @section_1_bg;
          }

          /*
              ┓ ┏┏┓┳┓┓┏┓┏┓┏┓┏┓┏┓┏┓┏┓
              ┃┃┃┃┃┣┫┃┫ ┗┓┃┃┣┫┃ ┣ ┗┓
              ┗┻┛┗┛┛┗┛┗┛┗┛┣┛┛┗┗┛┗┛┗┛
          */
          #workspaces {
              background: @section_2_bg;
              color: @section_2_fg;
          }
          #custom-workspaces-audio-separator {
              background: linear-gradient(120deg, @section_2_bg 50%, @section_3_bg 50%);
              color: @section_2_bg;
          }

          /*
              ┏┓┳┳┳┓┳┏┓
              ┣┫┃┃┃┃┃┃┃
              ┛┗┗┛┻┛┻┗┛
          */
          #pulseaudio {
              background: @section_3_bg;
              color: @section_3_fg
          }
          #custom-audio-separator {
              background: linear-gradient(120deg, @section_3_bg 50%, transparent 50%);
              color: @section_3_bg;
          }

          /*
            ┳┓┏┓┏┓┏┓┳┳┳┓┏┓┏┓┏┓
            ┣┫┣ ┗┓┃┃┃┃┣┫┃ ┣ ┗┓
            ┛┗┗┛┗┛┗┛┗┛┛┗┗┛┗┛┗┛
          */
          #custom-resources-separator {
              background: linear-gradient(120deg, transparent 50%, @section_3_bg 50%);
              color: @section_3_bg;
          }
          #resources {
              background: @section_3_bg;
              color: @section_3_fg
          }
          #custom-resources-temperature-separator {
              background: linear-gradient(120deg, @section_3_bg 50%, @section_2_bg 50%);
              color: @section_3_bg;
          }

          /*
              ┏┳┓┏┓┳┳┓┏┓┏┓┳┓┏┓┏┳┓┳┳┳┓┏┓
              ┃ ┣ ┃┃┃┃┃┣ ┣┫┣┫ ┃ ┃┃┣┫┣
              ┻ ┗┛┛ ┗┣┛┗┛┛┗┛┗ ┻ ┗┛┛┗┗┛
          */
          #temperature {
              background: @section_2_bg;
              color: @section_2_fg;
          }
          #custom-gpu {
              background: @section_2_bg;
              color: @section_2_fg;
          }
          #custom-temperature-system-separator {
              background: linear-gradient(120deg, @section_2_bg 50%, @section_1_bg 50%);
              color: @section_2_bg;
          }

          /*
              ┏┓┓┏┏┓┏┳┓┏┓┳┳┓
              ┗┓┗┫┗┓ ┃ ┣ ┃┃┃
              ┗┛┗┛┗┛ ┻ ┗┛┛ ┗
          */
          #system {
              background: @section_1_bg;
              color: @section_1_fg
          }
        '';
    };
  };
}
