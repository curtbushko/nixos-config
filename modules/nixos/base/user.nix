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

  nix = {
    # We need to enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      eval-cache = true
    '';

    # Add some garbage collection and cleanup of nix
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      # Build performance settings
      cores = 0; # Use all available cores for each build
      max-jobs = "auto"; # Auto-detect optimal number of parallel jobs

      # Parallel downloads for faster substitution
      http-connections = 128;
      max-substitution-jobs = 128;

      # Network optimization
      connect-timeout = 5;
      stalled-download-timeout = 30;
      download-attempts = 3;
      download-buffer-size = 256; # Default is 64 MiB

      inherit (import ../../shared/nix-caches.nix) substituters trusted-public-keys;
      trusted-users = ["root" "@wheel"];
    };
  };
}
