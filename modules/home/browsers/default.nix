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
      app_dst="$HOME/Applications/Firefox.app"
      if [ -e "$app_src" ]; then
        $DRY_RUN_CMD ln -sfn "$app_src" "$app_dst"
      fi
    '');
  };
}
