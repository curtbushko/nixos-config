{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  isDarwin = pkgs.stdenv.isDarwin;
  stylixEnabled = config.stylix.enable or false;
  wallpaper = config.stylix.image;
in {
  config = mkIf (stylixEnabled && isDarwin && wallpaper != null) {
    # Set macOS wallpaper using osascript activation script
    home.activation.setDarwinWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD /usr/bin/osascript -e '
        tell application "System Events"
          tell every desktop
            set picture to "${wallpaper}"
          end tell
        end tell
      '
    '';
  };
}
