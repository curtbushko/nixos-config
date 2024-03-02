{
  xdg.configFile = {
    "ghostty/config".text = builtins.readFile ./ghostty.config;
  };
}
