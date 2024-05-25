{
  inputs,
  pkgs,
  ...
}: {
  homebrew = {
    enable = true;
    brews  = [];
    taps = [];
    casks = [
      #"discord"
      "docker"
      "firefox"
      "obs"
      "obsidian"
      "rectangle"
      "syncthing"
      "slack"
      "vlc"
      "notunes"
    ];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.curtbushko = {
    home = "/Users/curtbushko";
    shell = pkgs.zsh;
  };
}
