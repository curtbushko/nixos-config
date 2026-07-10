{
  config,
  lib,
  pkgs,
  ...
}: {
  # Disable automatic software updates
  system.defaults.SoftwareUpdate = {
    AutomaticallyInstallMacOSUpdates = false;
  };

  # Disable the Software Update notification agent via launchctl
  # This prevents the annoying "Software Update Available" notifications
  system.activationScripts.postActivation.text = ''
    # Get the current user (console owner)
    CURRENT_USER=$(/usr/bin/stat -f %Su /dev/console)
    USER_UID=$(/usr/bin/id -u "$CURRENT_USER")

    # Disable Software Update notification manager (runs as user)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.SoftwareUpdateNotificationManager" 2>/dev/null || true

    # Turn off automatic update scheduling (runs as root)
    /usr/sbin/softwareupdate --schedule off 2>/dev/null || true
  '';
}
