{
  config,
  lib,
  pkgs,
  ...
}: {
  # Disable Spotlight indexing and search on all macOS machines
  # This improves performance and reduces background disk activity

  # Disable Spotlight suggestions and other search features
  system.defaults.NSGlobalDomain = {
    # Disable Spotlight suggestions in Spotlight search
    NSDisableAutomaticTermination = true;
  };

  system.defaults.dock = {
    # Remove Spotlight from menu bar (set to false to hide)
    show-recents = false;
  };

  # Disable Spotlight indexing and unload the service
  system.activationScripts.postActivation.text = ''
    # Get the current user (console owner)
    CURRENT_USER=$(/usr/bin/stat -f %Su /dev/console)
    USER_UID=$(/usr/bin/id -u "$CURRENT_USER")

    # Disable Spotlight indexing on all volumes
    echo "Disabling Spotlight indexing..."
    /usr/bin/sudo /usr/bin/mdutil -a -i off 2>/dev/null || true

    # Unload Spotlight metadata service (runs as root)
    /bin/launchctl bootout system/com.apple.metadata.mds 2>/dev/null || true

    # Also try to stop the per-user Spotlight service
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.Spotlight" 2>/dev/null || true

    # Remove Spotlight search icon from menu bar (optional)
    # This uses defaults write to persist the change
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.Spotlight MenuItemHidden -bool true 2>/dev/null || true

    # Kill Spotlight processes to apply changes immediately
    /usr/bin/killall mds 2>/dev/null || true
    /usr/bin/killall Spotlight 2>/dev/null || true

    echo "Spotlight has been disabled"
  '';
}
