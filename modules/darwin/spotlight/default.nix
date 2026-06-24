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

  # Disable Spotlight indexing and unload all services
  system.activationScripts.postActivation.text = ''
    # Get the current user (console owner)
    CURRENT_USER=$(/usr/bin/stat -f %Su /dev/console)
    USER_UID=$(/usr/bin/id -u "$CURRENT_USER")

    # Disable Spotlight indexing on all volumes
    echo "Disabling Spotlight indexing..."
    /usr/bin/sudo /usr/bin/mdutil -a -i off 2>/dev/null || true

    # Disable all Spotlight-related launchd services (system domain)
    echo "Disabling Spotlight system services..."
    /usr/bin/sudo /bin/launchctl disable system/com.apple.metadata.mds 2>/dev/null || true
    /usr/bin/sudo /bin/launchctl disable system/com.apple.metadata.mds.index 2>/dev/null || true
    /usr/bin/sudo /bin/launchctl disable system/com.apple.metadata.mds.scan 2>/dev/null || true

    # Disable user-level Spotlight services
    echo "Disabling Spotlight user services..."
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.Spotlight" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.corespotlightd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.corespotlightservice" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.spotlightknowledged" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.spotlightknowledged.importer" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.spotlightknowledged.updater" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.managedcorespotlightd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.metadata.mdbulkimport" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.metadata.mdflagwriter" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.metadata.mdwrite" 2>/dev/null || true

    # Bootout (unload) all running Spotlight services
    echo "Unloading Spotlight services..."
    /usr/bin/sudo /bin/launchctl bootout system/com.apple.metadata.mds 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.Spotlight" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.corespotlightd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.corespotlightservice" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.spotlightknowledged" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.spotlightknowledged.importer" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.spotlightknowledged.updater" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.managedcorespotlightd" 2>/dev/null || true

    # Remove Spotlight search icon from menu bar
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.Spotlight MenuItemHidden -bool true 2>/dev/null || true

    # Kill all Spotlight-related processes
    echo "Stopping Spotlight processes..."
    /usr/bin/killall mds 2>/dev/null || true
    /usr/bin/killall Spotlight 2>/dev/null || true
    /usr/bin/killall corespotlightd 2>/dev/null || true
    /usr/bin/killall managedcorespotlightd 2>/dev/null || true
    /usr/bin/killall spotlightknowledged 2>/dev/null || true
    /usr/bin/killall mdbulkimport 2>/dev/null || true

    echo "Spotlight has been disabled"
  '';
}
