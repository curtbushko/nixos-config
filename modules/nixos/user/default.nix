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
    extraGroups = ["docker" "wheel"];
    shell = pkgs.zsh;
  };
}
