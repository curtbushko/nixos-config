{
  config,
  lib,
  ...
}: let
  cfg = config.ns.wm.omniwm;
  defaults = import ./defaults.nix;
in {
  options.ns.wm.omniwm.enable = lib.mkEnableOption "macOS integration for OmniWM";

  config = lib.mkIf cfg.enable {
    system.defaults =
      defaults
      // {
        # Override the shared macOS preferences without changing the other Macs.
        trackpad = lib.mapAttrs (_: value: lib.mkForce value) defaults.trackpad;
      };
  };
}
