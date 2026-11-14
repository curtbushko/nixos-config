{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.shells;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in {
  options.ns.shells = {
    primaryMonitorBus = mkOption {
      type = types.ints.unsigned;
      default = 5;
      description = "I2C bus for the primary Dell monitor used by Linux monitor aliases.";
    };
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable shells
      '';
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      COLORTERM = "truecolor";
      PODMAN_NO_EMOJI = "1";
    };
  };

  imports = [
    ./bash.nix
    ./zsh.nix
  ];
}
