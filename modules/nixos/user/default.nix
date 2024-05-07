{
  inputs,
  pkgs,
  ...
}: {
  environment.localBinInPath = true;

  programs.zsh.enable = true;

  users.users.curtbushko = {
    isNormalUser = true;
    home = "/home/curtbushko";
    extraGroups = ["input" "networkmanager" "docker" "wheel" "i2c"];
    shell = pkgs.zsh;
  };
}
