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
}
