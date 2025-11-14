{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.wm;

  # Custom xkeyboard-config with additional keysyms
  xkeyboard-config-custom = pkgs.xkeyboard_config.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      # Add missing keysym definitions to prevent xkbcomp warnings
      cat >> $out/share/X11/xkb/symbols/inet <<'EOF'

// Additional multimedia and accessibility keys
partial alphanumeric_keys
xkb_symbols "evdev_custom" {
    key <I372> { [ XF86DoNotDisturb ] };
    key <I602> { [ XF86Accessibility ] };
    key <I234> { [ XF86RefreshRateToggle ] };
};
EOF
    '';
  });
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wayland
      egl-wayland
      libsForQt5.qt5.qtwayland
    ];

    # Use custom xkeyboard-config system-wide
    services.xserver.xkb.dir = "${xkeyboard-config-custom}/share/X11/xkb";

    # Enable xdg-desktop-portal at system level
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
      ];
      config = {
        common = {
          default = [ "gnome" ];
          "org.freedesktop.impl.portal.Settings" = [ "gnome" ];
        };
      };
    };

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
    # security.polkit.extraConfig = ''
    #   polkit.addRule(function(action, subject) {
    #       if (action.id == "org.freedesktop.login1.suspend" ||
    #           action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
    #           action.id == "org.freedesktop.login1.hibernate" ||
    #           action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
    #       {
    #           return polkit.Result.NO;
    #       }
    #   });
    # '';
  };
}
