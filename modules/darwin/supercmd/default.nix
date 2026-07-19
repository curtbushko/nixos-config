{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.supercmd;
in {
  options.ns.supercmd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to install SuperCmd via Homebrew";
    };
  };

  config = mkIf cfg.enable {
    homebrew.taps = ["supercmdlabs/supercmd"];
    homebrew.casks = ["supercmd"];
  };
}
