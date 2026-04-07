{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.man
      pkgs.util-linux # provides col
    ];
    xdg.configFile."television/cable/man-pages.toml".text = ''
      [metadata]
      name = "man-pages"
      description = "Browse and preview system manual pages"
      requirements = ["apropos", "man"]

      [source]
      command = "apropos ."

      [preview]
      command = "${pkgs.man}/bin/man '{0}' | ${pkgs.util-linux}/bin/col -bx"
      env = { "MANWIDTH" = "80" }

      [keybindings]
      enter = "actions:open"

      [actions.open]
      description = "Open the selected man page in the system pager"
      command = "${pkgs.man}/bin/man '{0}'"
      mode = "execute"

      [ui.preview_panel]
      header = "{0}"
    '';
  };
}
