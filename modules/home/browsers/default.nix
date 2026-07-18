{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.browsers;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.ns.browsers = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable browsers
      '';
    };
  };

  imports = [
    ./firefox.nix
  ];

  config = mkIf cfg.enable {
    home.packages =
      [
      ]
      ++ (lib.optionals isLinux [
        ]);

    home.activation.aliasFirefox = lib.mkIf isDarwin (config.lib.dag.entryAfter ["linkGeneration"] ''
      app_src="$HOME/Applications/Home Manager Apps/Firefox.app"
      app_dst="/Applications/Firefox.app"
      if [ -e "$app_src" ]; then
        $DRY_RUN_CMD rm -f "$app_dst"
        $DRY_RUN_CMD /usr/bin/osascript -e "
          tell application \"Finder\"
            make alias file to POSIX file \"$app_src\" at POSIX file \"/Applications/\"
            set name of result to \"Firefox.app\"
          end tell"
      fi
    '');
  };
}
