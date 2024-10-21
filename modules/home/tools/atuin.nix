{
  ...
}: {
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;
      #sync_frequency = "5m";
      #sync_address = "https://api.atuin.sh";
      enter_accept = false;
      style = "compact";
      keymap_mode = "vim-normal";
      history_filter = [
        "cd"
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
}
