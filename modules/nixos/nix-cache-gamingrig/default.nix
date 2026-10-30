{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ns.nix-cache-gamingrig;
in {
  options.ns.nix-cache-gamingrig = {
    enable = mkEnableOption "Use gamingrig as a remote builder";

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

    # Keep the remote builder and use public binary caches directly.
    nix.settings = {
      substituters = [
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
