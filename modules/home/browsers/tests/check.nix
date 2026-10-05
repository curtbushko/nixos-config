let
  colors = {
    base00 = "#101112";
    base01 = "#202122";
    base02 = "#303132";
    base03 = "#404142";
    base05 = "#d0d1d2";
    base0D = "#708090";
  };
  firefoxFor = isDarwin:
    (import ../firefox.nix {
      inputs = {};
      config = {
        ns.browsers.enable = true;
        lib.stylix.colors.withHashtag = colors;
      };
      lib = {
        mkIf = condition: content:
          if condition
          then content
          else {};
        mkAfter = content: content;
      };
      pkgs.stdenv = {
        inherit isDarwin;
        isLinux = !isDarwin;
      };
    }).config;
  darwin = firefoxFor true;
  linux = firefoxFor false;
in
  assert darwin.stylix.targets.firefox.profileNames == ["default"];
  assert !darwin.stylix.targets.firefox.colorTheme.enable;
  assert !linux.stylix.targets.firefox.colorTheme.enable;
  assert darwin.programs.firefox.profiles.default.userChrome == linux.programs.firefox.profiles.default.userChrome;
  assert builtins.all (platform:
    platform.programs.firefox.profiles.default.settings."toolkit.legacyUserProfileCustomizations.stylesheets") [darwin linux];
  assert builtins.all (expected:
    builtins.match ".*${expected}.*" darwin.programs.firefox.profiles.default.userChrome != null) [
    "--lwt-accent-color: #101112 !important;"
    "--toolbox-bgcolor: #101112 !important;"
    "#navigator-toolbox, #TabsToolbar, #titlebar [{][[:space:]]*background-color: #101112 !important;"
    "--toolbar-bgcolor: #101112 !important;"
    "--toolbar-color: #d0d1d2 !important;"
    "--toolbar-field-background-color: #303132 !important;"
    "--toolbar-field-border-color: #404142 !important;"
    "--focus-outline-color: #708090 !important;"
  ]; true
