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
      pkgs.fd
    ];
    xdg.configFile."television/cable/files.toml".text = ''
      [metadata]
      name = "files"
      description = "A channel to select files and directories"
      requirements = ["fd", "bat"]

      [source]
      command = ["fd -t f", "fd -t f -H"]

      [preview]
      command = "bat -n --color=always '{}'"
      env = { BAT_THEME = "ansi" }

      [keybindings]
      shortcut = "f1"
      enter = "actions:open-in-nvim"
      ctrl-up = "actions:goto_parent_dir"

      [actions.open-in-nvim]
      description = "Open in neovim"
      command = "nvim '{}'"
      mode = "execute"

      [actions.goto_parent_dir]
      description = "Re-opens tv in the parent directory"
      command = "tv files .."
      mode = "execute"
    '';
  };
}
