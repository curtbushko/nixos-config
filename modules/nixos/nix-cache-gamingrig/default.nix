{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.curtbushko.nix-cache-gamingrig;
in {
  options.curtbushko.nix-cache-gamingrig = {
    enable = mkEnableOption "Use gamingrig as primary binary cache with wake-on-lan support";

    relayHost = mkOption {
      type = types.str;
      default = "relay";
      description = "Relay host to bounce wake-on-lan through";
    };
  };

  config = mkIf cfg.enable {
    # Install etherwake for relay host (wakeonlan provided by home-manager scripts)
    environment.systemPackages = with pkgs; [
      etherwake
    ];

    # Configure Nix to use gamingrig cache with builder
    nix.settings = {
      substituters = [
        "http://gamingrig:5000" # nix-serve: Local /nix/store (fastest, 173GB)
        "http://gamingrig:8501" # ncps: Pull-through cache (LRU, 100GB)
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Use gamingrig as remote builder
      builders = [
        "ssh://curtbushko@gamingrig x86_64-linux,armv7l-linux /home/curtbushko/.ssh/id_ed25519 8 - nixos-test,benchmark,big-parallel,kvm"
      ];
      builders-use-substitutes = true;
    };
  };
}
