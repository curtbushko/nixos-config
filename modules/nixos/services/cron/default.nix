{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.curtbushko.services.cron;
in {
  options.curtbushko.services.cron = {
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
    services.cron = {
      enable = true;
      systemCronJobs = [
        # Run daily at 2:00 AM - nix garbage collection
        "0 2 * * * root ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 7d"

        # Run daily at 2:00 AM - delete old generations
        "0 2 * * * root ${pkgs.nix}/bin/nix-env --delete-generations +3"

        # Run daily at 2:00 AM - nix store garbage collection
        "0 2 * * * root ${pkgs.nix}/bin/nix-store --gc"
      ];
    };
  };
}
