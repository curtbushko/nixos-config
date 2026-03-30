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
      pkgs.tealdeer
    ];

    programs.zsh.shellAliases = {
      tldr = "tv tldr";
    };

    # Tealdeer config with auto-update enabled
    xdg.configFile."tealdeer/config.toml".text = ''
      [updates]
      auto_update = true
    '';

    # Ensure tldr cache is populated on activation
    home.activation.updateTldrCache = config.lib.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.cache/tealdeer" ] || [ -z "$(ls -A $HOME/.cache/tealdeer 2>/dev/null)" ]; then
        $DRY_RUN_CMD ${pkgs.tealdeer}/bin/tldr --update || true
      fi
    '';

    xdg.configFile."television/cable/tldr.toml".text = ''
      [metadata]
      name = "tldr"
      description = "Browse and preview TLDR help pages for command-line tools"
      requirements = ["tldr"]

      [source]
      command = "tldr --list"

      [preview]
      command = "tldr '{0}'"

      [keybindings]
      ctrl-e = "actions:open"

      [actions.open]
      description = "Open the selected TLDR page"
      command = "tldr '{0}'"
      mode = "execute"
    '';
  };
}
