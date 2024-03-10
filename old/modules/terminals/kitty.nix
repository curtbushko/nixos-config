{
  programs.kitty = {
    extraConfig = builtins.readFile ./kitty;
  };
}
