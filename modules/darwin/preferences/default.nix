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
  };

  # CustomUserPreferences for settings without dedicated nix-darwin options
  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      AppleActionOnDoubleClick = "None"; # Disable double-click title bar to maximize
      "com.apple.swipescrolldirection" = false; # Disable natural scrolling
    };
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

  # Trackpad
  system.defaults.trackpad = {
    ActuateDetents = true;
    Clicking = false;
    DragLock = false;
    Dragging = false;
    FirstClickThreshold = 1;
    ForceSuppressed = false;
    SecondClickThreshold = 1;
    TrackpadCornerSecondaryClick = 2;
    TrackpadFourFingerHorizSwipeGesture = 2;
    TrackpadFourFingerPinchGesture = 2;
    TrackpadFourFingerVertSwipeGesture = 2;
    TrackpadMomentumScroll = true;
    TrackpadPinch = true;
    TrackpadRightClick = false;
    TrackpadRotate = true;
    TrackpadThreeFingerDrag = false;
    TrackpadThreeFingerHorizSwipeGesture = 2;
    TrackpadThreeFingerTapGesture = 0;
    TrackpadThreeFingerVertSwipeGesture = 2;
    TrackpadTwoFingerDoubleTapGesture = true;
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
  };

  # Global trackpad settings
  system.defaults.NSGlobalDomain."com.apple.trackpad.forceClick" = true;

  system.activationScripts.postActivation.text = ''
    CURRENT_USER=$(/usr/bin/stat -f %Su /dev/console)

    # Keyboard shortcuts - Cmd+Left/Right arrow to switch desktops
    # Uses defaults write with nested plist dicts which CustomUserPreferences can't handle
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 '
      <dict>
        <key>enabled</key><true/>
        <key>value</key><dict>
          <key>parameters</key><array>
            <integer>65535</integer><integer>123</integer><integer>1048576</integer>
          </array>
          <key>type</key><string>standard</string>
        </dict>
      </dict>'
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 '
      <dict>
        <key>enabled</key><true/>
        <key>value</key><dict>
          <key>parameters</key><array>
            <integer>65535</integer><integer>123</integer><integer>1179648</integer>
          </array>
          <key>type</key><string>standard</string>
        </dict>
      </dict>'
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 '
      <dict>
        <key>enabled</key><true/>
        <key>value</key><dict>
          <key>parameters</key><array>
            <integer>65535</integer><integer>124</integer><integer>1048576</integer>
          </array>
          <key>type</key><string>standard</string>
        </dict>
      </dict>'
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 '
      <dict>
        <key>enabled</key><true/>
        <key>value</key><dict>
          <key>parameters</key><array>
            <integer>65535</integer><integer>124</integer><integer>1179648</integer>
          </array>
          <key>type</key><string>standard</string>
        </dict>
      </dict>'

    # Trackpad and symbolic hotkey settings require a logout/login to take effect.
    # cfprefsd kill + activateSettings helps some settings reload without logout.
    launchctl asuser "$(/usr/bin/id -u "$CURRENT_USER")" /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/killall cfprefsd 2>/dev/null || true
    /usr/bin/killall cfprefsd 2>/dev/null || true
    sleep 1
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
    echo >&2 "NOTE: Trackpad and keyboard shortcut changes require logout/login to take effect."
  '';
}
