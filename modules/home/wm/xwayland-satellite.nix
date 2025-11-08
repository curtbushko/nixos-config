{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;

  # Get the custom xkeyboard-config from system if available
  xkbDir = osConfig.services.xserver.xkb.dir or "${pkgs.xkeyboard_config}/share/X11/xkb";
in {
  config = mkIf cfg.enable {
    systemd.user.services.xwayland-satellite = {
      Unit = {
        Description = "Xwayland outside your Wayland";
        BindsTo = "graphical-session.target";
        PartOf = "graphical-session.target";
        After = "graphical-session.target";
        Requisite = "graphical-session.target";
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        Type = "notify";
        NotifyAccess = "all";
        ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        StandardOutput = "journal";
        StandardError = "journal";
        Environment = [
          # XKB configuration to match system settings
          "XKB_DEFAULT_RULES=evdev"
          "XKB_DEFAULT_MODEL=pc105"
          "XKB_DEFAULT_LAYOUT=us"
          "XKB_DEFAULT_VARIANT="
          "XKB_DEFAULT_OPTIONS=caps:escape"
          # Use custom XKB configuration directory
          "XKB_CONFIG_ROOT=${xkbDir}"
          # Disable glamor for better compatibility
          "XWAYLAND_NO_GLAMOR=1"
        ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
