{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      # disable up arrow key
      flags = [ "--disable-up-arrow" ];
      settings = {
        auto_sync = false;
        #sync_frequency = "5m";
        #sync_address = "https://api.atuin.sh";
        enter_accept = false;
        style = "compact";
        keymap_mode = "vim-normal";
        history_filter = [
          "ls"
          "pwd"
          "foo"
          "bar"
          "baz"
          "src"
          "dest"
          "cddest"
          "cdsrc"
          "exit"
          "gs"
        ];
      };
    };
  };
}
