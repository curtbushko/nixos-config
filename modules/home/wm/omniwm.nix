{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ns.wm.omniwm;
  settingsFormat = pkgs.formats.toml {};
  bindings = import ./omniwm/bindings.nix;
  skhdConfig = pkgs.writeText "omniwm-skhdrc" (import ./omniwm/render-skhd.nix bindings);
in {
  options.ns.wm.omniwm.enable = lib.mkEnableOption "OmniWM with niri-style shortcuts (installed through Homebrew)";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "OmniWM requires macOS on Apple Silicon.";
      }
      {
        assertion = !config.ns.wm.rectangle.enable;
        message = "Disable Rectangle before enabling OmniWM to avoid conflicting window managers.";
      }
    ];

    # Disabling the Rectangle module alone would leave its old login preference.
    targets.darwin.defaults."com.knollsoft.Rectangle".launchOnLogin = false;
    home.packages = [pkgs.skhd];
    xdg.configFile = {
      "omniwm/settings.toml".source = settingsFormat.generate "omniwm-settings.toml" (import ./omniwm/settings.nix);
      "omniwm/skhdrc".source = skhdConfig;
      "omniwm/KEYBINDINGS.md".source = ./omniwm/README.md;
    };

    launchd.agents.omniwm-hotkeys = {
      enable = true;
      config = {
        ProgramArguments = ["${pkgs.skhd}/bin/skhd" "-c" "${skhdConfig}"];
        EnvironmentVariables = {
          PATH = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          SHELL = "/bin/bash";
        };
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/omniwm-hotkeys.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/omniwm-hotkeys.log";
      };
    };
  };
}
