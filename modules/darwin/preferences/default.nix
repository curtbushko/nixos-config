{
  config,
  lib,
  pkgs,
  ...
}: {
  # macOS UI/UX Preferences
  # Captured from current system defaults that differ from Apple defaults

  # Dock
  system.defaults.dock = {
    orientation = "left";
    tilesize = 25;
    launchanim = false;
    mru-spaces = false;
  };

  # Finder
  system.defaults.finder = {
    ShowPathbar = true;
    ShowStatusBar = true;
    FXPreferredViewStyle = "Nlsv";
  };

  # Global preferences
  system.defaults.NSGlobalDomain = {
    AppleInterfaceStyle = "Dark";
    "com.apple.swipescrolldirection" = false;
  };

  # Window Manager - disable all tiling, hide widgets
  system.defaults.WindowManager = {
    EnableTiledWindowMargins = false;
    EnableTilingByEdgeDrag = false;
    EnableTilingOptionAccelerator = false;
    EnableTopTilingByEdgeDrag = false;
    HideDesktop = true;
    StandardHideWidgets = true;
    StageManagerHideWidgets = true;
  };

  # Menu bar clock - hide date
  system.defaults.menuExtraClock = {
    ShowDate = 0;
  };

  # Trackpad - 3-finger vertical swipe for Mission Control / App Expose
  system.defaults.trackpad = {
    TrackpadThreeFingerVertSwipeGesture = 2;
  };

  # Keyboard shortcuts - Cmd+Left/Right arrow to switch desktops
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "79" = {
          enabled = true;
          value = {
            parameters = [65535 123 1048576];
            type = "standard";
          };
        };
        "80" = {
          enabled = true;
          value = {
            parameters = [65535 123 1179648];
            type = "standard";
          };
        };
        "81" = {
          enabled = true;
          value = {
            parameters = [65535 124 1048576];
            type = "standard";
          };
        };
        "82" = {
          enabled = true;
          value = {
            parameters = [65535 124 1179648];
            type = "standard";
          };
        };
      };
    };
  };
}
