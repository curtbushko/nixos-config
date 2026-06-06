{inputs, lib, ...}: {
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  # Disable stylix - it pulls in packages that don't support armv7l-linux
  stylix.enable = lib.mkForce false;

  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  # Enable XDG to allow nix configuration to be written to ~/.config/nix/nix.conf
  # This is required for remote builder configuration to work on standalone Nix
  xdg.enable = true;

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
      # Automatic space management for limited Raspberry Pi storage
      # Trigger GC when less than 500MB free
      min-free = 500 * 1024 * 1024;
      # Target 1GB free after GC
      max-free = 1024 * 1024 * 1024;
      # Enable auto-optimization to save space via hardlinking
      auto-optimise-store = true;
    };

    # Automatic garbage collection - critical for limited storage
    gc = {
      automatic = true;
      # Run daily
      frequency = "daily";
      # Keep only last 2 generations (minimal for space-constrained system)
      options = "--delete-older-than 2d";
    };

    # Configure gamingrig as remote builder
    buildMachines = [
      {
        hostName = "gamingrig";
        sshUser = "curtbushko";
        sshKey = "/home/curtbushko/.ssh/id_ed25519";
        # gamingrig is x86_64 but can build armv7l via binfmt emulation
        system = "x86_64-linux";
        systems = [ "x86_64-linux" "armv7l-linux" ];
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        maxJobs = 8;
        # Prefer substitutes over building to save time
        mandatoryFeatures = [ ];
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
