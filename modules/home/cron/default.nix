{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.curtbushko.cron;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.curtbushko.cron = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable automated nix maintenance cron jobs.
        Jobs run daily at 2:00 AM and include:
        - nix-collect-garbage: Remove store paths older than 7 days
        - nix-delete-generations: Keep only the most recent 3 generations
        - nix-store-gc: Run garbage collection on the nix store
      '';
    };
  };

  config = mkIf cfg.enable {
    # Linux: systemd user services and timers
    systemd.user.services = mkIf isLinux {
      auto-nix-collect-garbage = {
        Unit = {
          Description = "Nix garbage collection - delete store paths older than 7 days";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 7d";
        };
      };

      auto-nix-delete-generations = {
        Unit = {
          Description = "Nix delete generations - keep only the most recent 3 generations";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.nix}/bin/nix-env --delete-generations +3";
        };
      };

      auto-nix-store-gc = {
        Unit = {
          Description = "Nix store garbage collection";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.nix}/bin/nix-store --gc";
        };
      };
    };

    systemd.user.timers = mkIf isLinux {
      auto-nix-collect-garbage = {
        Unit = {
          Description = "Timer for nix garbage collection";
        };
        Timer = {
          OnCalendar = "02:00";
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };

      auto-nix-delete-generations = {
        Unit = {
          Description = "Timer for nix delete generations";
        };
        Timer = {
          OnCalendar = "02:00";
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };

      auto-nix-store-gc = {
        Unit = {
          Description = "Timer for nix store garbage collection";
        };
        Timer = {
          OnCalendar = "02:00";
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };
    };

    # macOS: launchd agents
    launchd.agents = mkIf isDarwin {
      auto-nix-collect-garbage = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.nix}/bin/nix-collect-garbage"
            "--delete-older-than"
            "7d"
          ];
          StartCalendarInterval = [
            {
              Hour = 2;
              Minute = 0;
            }
          ];
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/nix-collect-garbage.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/nix-collect-garbage.log";
        };
      };

      auto-nix-delete-generations = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.nix}/bin/nix-env"
            "--delete-generations"
            "+3"
          ];
          StartCalendarInterval = [
            {
              Hour = 2;
              Minute = 0;
            }
          ];
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/nix-delete-generations.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/nix-delete-generations.log";
        };
      };

      auto-nix-store-gc = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.nix}/bin/nix-store"
            "--gc"
          ];
          StartCalendarInterval = [
            {
              Hour = 2;
              Minute = 0;
            }
          ];
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/nix-store-gc.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/nix-store-gc.log";
        };
      };
    };
  };
}
