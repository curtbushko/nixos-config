{pkgs, ...}: {
  environment.localBinInPath = true;

  programs.zsh.enable = true;

  users.users.curtbushko = {
    isNormalUser = true;
    home = "/home/curtbushko";
    extraGroups = ["input" "networkmanager" "docker" "wheel" "i2c" "jackaudio" "audio" "adbusers"];
    shell = pkgs.zsh;
  };
  security.sudo.wheelNeedsPassword = false;

  # Keep in async with vm-shared.nix. (todo: pull this out into a file)
  nix = {
    # We need to enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      eval-cache = true
    '';

    settings = {
      # Build performance settings
      cores = 0;  # Use all available cores for each build
      max-jobs = "auto";  # Auto-detect optimal number of parallel jobs

      # Parallel downloads for faster substitution
      http-connections = 128;
      max-substitution-jobs = 128;

      # Network optimization
      connect-timeout = 5;
      stalled-download-timeout = 30;
      download-attempts = 3;

      # Binary caches
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "nur.cachix.org-1:A7D5BYF/R3HDVC1+laJQd9cRdQEdoBP/jbESNLfLscY="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "mitchellh.cachix.org-1:1b3lQ7+tlqfNhQGjx1LY0AJPt0hV5sWqVYyL4UQNV0Q="
      ];
      trusted-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://claude-code.cachix.org"
        "https://ghostty.cachix.org"
        "https://nur.cachix.org"
        "https://niri.cachix.org"
        "https://mitchellh.cachix.org"
      ];
      trusted-users = ["root" "@wheel"];
    };
  };
}
