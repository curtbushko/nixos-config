{
  inputs,
  pkgs,
  system,
  ...
}: {
  homebrew = {
    enable = true;
    brews = [];
    taps = [];
    casks = [
      #"discord"
      "firefox"
      "obs"
      "obsidian"
      "rectangle"
      "slack"
      "vlc"
      "notunes"
    ];
  };

  # 2025-06-21 temporary hack as nix-darwin cleans things up
  system.primaryUser = "curtbushko";
  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.curtbushko = {
    home = "/Users/curtbushko";
    shell = pkgs.zsh;
  };
}
