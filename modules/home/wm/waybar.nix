{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  programs.waybar = {
    enable = isLinux;
    settings = [
      {
        layer = "top";
        position = "top";
        spacing = "-4";
        mod = "dock";
        height = 20;
        margin-top = 0;
        margin-bottom = 0;
        exclusive = true;
        passthrough = false;
        gtk-layer-shell = true;
        output = "DP-2";
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

        "hyprland/workspaces" = {
          on-scroll-up = "hyprctl dispatch workspace -1";
          on-scroll-down = "hyprctl dispatch workspace +1";
          all-outputs = true;
          active-only = false;
          on-click = "activate";
          persistent-workspaces."*" = 8;
        };

        "custom/workspaces-audio-separator" = {
            format = "{}    ";
        };

        pulseaudio = {
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
        };

        "custom/audio-separator" = {
            format = "{}    ";
        };

        modules-left = [
          "group/network"
          "custom/network-workspaces-separator"
          "hyprland/workspaces"
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

        modules-center = [
          "clock"
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
      inherit (inputs.nix-colors.lib.conversions) hexToRGBString;
      toRGBA = color: opacity: "rgba(${hexToRGBString "," (lib.removePrefix "#" color)},${opacity})";
      colors = config.colorScheme.palette;
    in
      with colors; ''
        /*
            ┏┓┓ ┏┳┓  ┏┓┏┓┓ ┏┓┳┓┏┓
            ┃┃┃┃┃┃┃  ┃ ┃┃┃ ┃┃┣┫┗┓
            ┗┛┗┻┛┛┗  ┗┛┗┛┗┛┗┛┛┗┗┛
        */
        @define-color foreground #${fg};
        @define-color background #${bg};
        @define-color cursor #afbbe5;

        /* waybar area/group colors*/
        @define-color network ${toRGBA bg "1.0"};
        @define-color workspaces ${toRGBA dark3 "1.0"};
        @define-color audio ${toRGBA blue "1.0"};
        @define-color clock @foreground;
        @define-color resources ${toRGBA blue "1.0"};
        @define-color temperature ${toRGBA dark3 "1.0"};
        @define-color system ${toRGBA bg "1.0"};

        /* workspace text colors */
        @define-color workspace_fg @foreground;
        @define-color act_wrk_fg  #${bg};
        @define-color use_wrk_fg #${blue8};
        /* workspace button-background colors */
        @define-color workspace_bg ${toRGBA bg "0.9"};
        @define-color act_wrk_bg ${toRGBA green "0.8"};

        /* updates-widget icon+text colors */
        @define-color updates_green #${green};
        @define-color updates_yellow #${yellow};
        @define-color updates_red #${red};
        /* tokyo-night colors
        updates_green = "#${green}";
        updates_yellow = "#${yellow}";
        updates_red = "${red}";
        */

        /*
            ┏┓┏┓┳┓┏┓┳┓┏┓┓
            ┃┓┣ ┃┃┣ ┣┫┣┫┃
            ┗┛┗┛┛┗┗┛┛┗┛┗┗┛
        */

        * {
            font-family: "Fira Sans SemiBold";
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
            border-width: 0px;
        }

        /*
            ┓ ┏┏┓┳┓┓┏┓┏┓┏┓┏┓┏┓┏┓┏┓
            ┃┃┃┃┃┣┫┃┫ ┗┓┃┃┣┫┃ ┣ ┗┓
            ┗┻┛┗┛┛┗┛┗┛┗┛┣┛┛┗┗┛┗┛┗┛
        */

        #workspaces {
            padding: 2px 10px;
        }

        /* ALL workspace buttons (Focused + Unfocused) */
        #workspaces button:hover {
        }

        /* Only focused workspace*/
        #workspaces button.active {
            color:  @act_wrk_fg;
            background: @act_wrk_bg;
            border: none;
            padding: 2px 5px;
            margin: 2px 2px;
            transition: all 0.2s ease-in-out;
        }

        /* Unfocused workspace WITH opened Apps
        !!! Border style is valid for ALL buttons,
        Set seperate border style for every button. */
        #workspaces button {
            color: @workspace_fg;
            background: @workspace_bg;
            padding: 2px 5px;
            margin: 2px 2px;
            transition: all 0.2s ease-in-out;
        }

        #workspaces button:not(.empty):not(.active) {
            color: @use_wrk_fg;
            padding: 2px 5px;
            margin: 2px 5px;
        }

        /*
            ┏┓┏┳┓┓┏┏┓┳┓
            ┃┃ ┃ ┣┫┣ ┣┫
            ┗┛ ┻ ┛┗┗┛┛┗
        */

        #clock {
            font-family: "Futura Bk BT";
            font-weight: bold;
            font-size: 14px;
            color: @clock;
            padding: 1px 5px 0px 5px;
            opacity: 1;
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
        #custom-updates, #custom-power, #custom-copyq, #custom-mako,
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
            background: @network;
        }
        #group-network {
            background: @network;
        }
        #custom-network-workspaces-separator {
           background: linear-gradient(120deg, @network 50%, #${dark3} 50%);
           color: @network;
        }

        /*
            ┓ ┏┏┓┳┓┓┏┓┏┓┏┓┏┓┏┓┏┓┏┓
            ┃┃┃┃┃┣┫┃┫ ┗┓┃┃┣┫┃ ┣ ┗┓
            ┗┻┛┗┛┛┗┛┗┛┗┛┣┛┛┗┗┛┗┛┗┛
        */
        #workspaces {
            background: @workspaces;
        }
        #custom-workspaces-audio-separator {
           background: linear-gradient(120deg, @workspaces 50%, #${blue} 50%);
           color: @workspaces;
        }

        /*
            ┏┓┳┳┳┓┳┏┓
            ┣┫┃┃┃┃┃┃┃
            ┛┗┗┛┻┛┻┗┛
        */
        #pulseaudio {
            background: @audio;
        }
        #custom-audio-separator {
           background: linear-gradient(120deg, @audio 50%, transparent 50%);
           color: @audio;
        }

        /*
          ┳┓┏┓┏┓┏┓┳┳┳┓┏┓┏┓┏┓
          ┣┫┣ ┗┓┃┃┃┃┣┫┃ ┣ ┗┓
          ┛┗┗┛┗┛┗┛┗┛┛┗┗┛┗┛┗┛
        */
        #custom-resources-separator {
           background: linear-gradient(120deg, transparent 50%, #${blue} 50%);
           color: @resources;
        }
        #resources {
            background: @resources;
        }
        #custom-resources-temperature-separator {
           background: linear-gradient(120deg, @resources 50%, #${dark3} 50%);
           color: @resources;
        }

        /*
           ┏┳┓┏┓┳┳┓┏┓┏┓┳┓┏┓┏┳┓┳┳┳┓┏┓
            ┃ ┣ ┃┃┃┃┃┣ ┣┫┣┫ ┃ ┃┃┣┫┣
            ┻ ┗┛┛ ┗┣┛┗┛┛┗┛┗ ┻ ┗┛┛┗┗┛
        */
        #temperature {
            background: @temperature;
        }
        #custom-gpu {
            background: @temperature;
        }
        #custom-temperature-system-separator {
           background: linear-gradient(120deg, @temperature 50%, #${bg} 50%);
           color: @temperature;
        }

        /*
            ┏┓┓┏┏┓┏┳┓┏┓┳┳┓
            ┗┓┗┫┗┓ ┃ ┣ ┃┃┃
            ┗┛┗┛┗┛ ┻ ┗┛┛ ┗
        */
        #system {
            background: @system;
        }
      '';
  };
}
