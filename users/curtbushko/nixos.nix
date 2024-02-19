{ pkgs, inputs, ... }:

{

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.zsh.enable = true;

  users.users.mitchellh = {
    isNormalUser = true;
    home = "/home/curtbushko";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.zsh;
  };
}
