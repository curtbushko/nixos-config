{
  config,
  lib,
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  programs.waybar = {
    enable = isLinux;

    settings = [
      {
        layer = "top";
        height = 14;

        margin-right = "6px";
        margin-left = "6px";
        margin-top = "6px";

        modules-left = [
          "hyprland/workspaces"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons.default = "";
          format-icons.active = "";

          persistent-workspaces."*" = 5;
        };

        modules-center = [
          "hyprland/window"
        ];

        "hyprland/window" = {
          seperate-outputs = true;

          rewrite."(.*) - Discord" = "󰙯 $1";
          rewrite."(.*) — Mozilla Firefox" = "󰖟 $1";
          rewrite."(.*) — nu" = " $1";
        };

        modules-right = [
          "tray"
          "pulseaudio"
          "backlight"
          "cpu"
          "memory"
          "network"
          "battery"
          "clock"
        ];

        tray = {
          reverse-direction = true;
          spacing = 5;
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

        backlight = {
          format = "{icon} {percent}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
        };

        cpu.format = " {usage}%";
        memory.format = "󰽘 {}%";

        network = {
          format-disconnected = "󰤮 ";
          format-ethernet = "󰈀 {ipaddr}/{cidr}";
          format-linked = " {ifname} (No IP)";
          format-wifi = " {signalStrength}%";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰂄 {capacity}%";

          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];

          states.warning = 30;
          states.critical = 15;
        };

        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
      }
    ];

    style = ''
      * {
        border: none;
        border-radius: "8px";
      }

      .modules-right {
        margin-right: "8px;
      }

      #waybar {
        background: rgb(1A1B26);
        color: rgb(7aa2f7);
      }

      #workspaces button:nth-child(1) {
        color: rgb(FFEC6E);
      }

      #workspaces button:nth-child(2) {
        color: rgb(00b0fc);
      }

      #workspaces button:nth-child(3) {
        color: rgb(65bcff);
      }

      #workspaces button:nth-child(4) {
        color: rgb(019ef3);
      }

      #workspaces button:nth-child(5) {
        color: rgb(FFEC6E);
      }

      #tray, #pulseaudio, #backlight, #cpu, #memory, #network, #battery, #clock {
        margin-left: 20px;
      }

      @keyframes blink {
        to {
          color: rgb(FFEC6E);
        }
      }

      #battery.critical:not(.charging) {
        animation-direction: alternate;
        animation-duration: 0.5s;
        animation-iteration-count: infinite;
        animation-name: blink;
        animation-timing-function: linear;
        color: rgb(65bcff);
      }
    '';
  };
}
