{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.hardware.cpu;

  # Helper function to convert hex color to RGB string
  hexToRgb = hex: let
    # Remove # prefix if present
    cleanHex = lib.removePrefix "#" hex;
    # Convert hex to RGB values
    r = lib.toInt ("0x" + builtins.substring 0 2 cleanHex);
    g = lib.toInt ("0x" + builtins.substring 2 2 cleanHex);
    b = lib.toInt ("0x" + builtins.substring 4 2 cleanHex);
  in "${toString r} ${toString g} ${toString b}";

  # Use stylix colors if available, otherwise use default gruvbox colors
  gruvboxTheme = if config.stylix.enable or false then {
    accent = hexToRgb config.stylix.base16Scheme.base0D;           # Blue for accents
    bgOne = hexToRgb config.stylix.base16Scheme.base00;            # Main background
    bgTwo = hexToRgb config.stylix.base16Scheme.base02;            # Secondary background
    borderOne = "${hexToRgb config.stylix.base16Scheme.base0D} 0.25"; # Border with opacity
    textColor = hexToRgb config.stylix.base16Scheme.base05;        # Main foreground text
    textColorSecondary = hexToRgb config.stylix.base16Scheme.base03; # Secondary text
  } else {
    # Fallback to default gruvbox colors
    accent = "131 165 152";
    bgOne = "40 40 40";
    bgTwo = "60 56 54";
    borderOne = "124 111 100 0.25";
    textColor = "235 219 178";
    textColorSecondary = "146 131 116";
  };
in {
  config = mkIf cfg.enable {
    programs.coolercontrol = {
      enable = true;
    };

    # Apply gruvbox theme to CoolerControl
    environment.etc."coolercontrol/config-ui.json" = {
      text = builtins.toJSON {
        devices = [];
        deviceSettings = [];
        dashboards = [];
        themeMode = "custom theme";
        chartLineScale = 1.5;
        time24 = false;
        collapsedMenuNodeIds = [];
        collapsedMainMenu = false;
        hideMenuCollapseIcon = false;
        menuEntitiesAtBottom = false;
        mainMenuWidthRem = 24.1;
        frequencyPrecision = 1;
        customTheme = gruvboxTheme;
        showOnboarding = false;
      };
    };
  };
}
