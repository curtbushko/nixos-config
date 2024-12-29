{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.wm;
in
{
  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      wayland
      egl-wayland
      libsForQt5.qt5.qtwayland
    ];

    programs.hyprland.enable = true;

    # Xserver settings
    services.xserver = {
      enable = true;
      dpi = 180;
      videoDrivers = ["nvidia"];
      xkb = {
        layout = "us";
        variant = "";
        options = "caps:escape";
      };

      displayManager = {
        lightdm = {
          enable = false;
        };
      };
    };
    # Used to disable gdm suspend.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.login1.suspend" ||
              action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
              action.id == "org.freedesktop.login1.hibernate" ||
              action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
          {
              return polkit.Result.NO;
          }
      });
    '';
  };
}
