{...}: {
  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  # XDG disabled to avoid pulling in unsupported packages
  xdg.enable = false;

  #---------------------------------------------------------------------
  # Nix Settings - Use gamingrig as remote builder
  # Relay (Raspberry Pi) lacks CPU/storage to build locally
  #---------------------------------------------------------------------
  nix = {
    settings = {
      # Enable flakes and nix command
      experimental-features = [ "nix-command" "flakes" ];
      # Use binary caches to avoid building when possible
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Ber7dSSWDNp2XQP1v3jdiPp4="
      ];
      # Allow building for this architecture
      extra-platforms = [ "armv7l-linux" ];
      # Trust the remote builder
      trusted-users = [ "root" "curtbushko" ];
      # Always delegate builds to remote builder
      max-jobs = 0;
      # Let remote builder use substituters to avoid unnecessary builds
      builders-use-substitutes = true;
    };

    # Configure gamingrig as remote builder
    buildMachines = [
      {
        hostName = "gamingrig";
        sshUser = "curtbushko";
        sshKey = "/home/curtbushko/.ssh/id_ed25519";
        system = "x86_64-linux";
        # gamingrig can emulate armv7l-linux via binfmt
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        maxJobs = 8;
      }
    ];

    # Enable distributed builds
    distributedBuilds = true;
  };

  #---------------------------------------------------------------------
  # Home Options - Minimal configuration for Raspberry Pi relay
  # Most modules disabled due to armv7l-linux limited package support
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = false;
    gamedev.enable = false;
    gaming.enable = false;
    git.enable = false;      # Disabled for armv7l compatibility
    k8s.enable = false;
    llm.enable = false;
    programming.enable = false;
    scripts.enable = false;
    secrets.enable = false;
    shells.enable = false;   # Disabled for armv7l compatibility
    terminals.enable = false;
    tools.enable = false;
    wm = {
      tools.enable = false;
      niri.enable = false;
      rofi.enable = false;
    };
  };

  #---------------------------------------------------------------------
  # Env vars
  #---------------------------------------------------------------------
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "vim";
    PAGER = "less -FirSwX";
  };
}
