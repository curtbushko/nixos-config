{
  pkgs,
  ...
}: {
  system.stateVersion = 5;

  # This makes it work with the Determinate Nix installer
  ids.gids.nixbld = 30000;
  # Enable touch for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Keep in async with vm-shared.nix. (todo: pull this out into a file)
  nix = {
    # We use the determinate-nix installer which manages Nix for us,
    # so we don't want nix-darwin to do it.
    enable = false;
    # We need to enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes external-builders
      keep-outputs = true
      keep-derivations = true
      eval-cache = true
    '';
    # Enable the Linux builder so we can run Linux builds on our Mac.
    # This can be debugged by running `sudo ssh linux-builder`
    linux-builder = {
      enable = false;
      ephemeral = true;
      maxJobs = 4;
      config = ({ pkgs, ... }: {
        # Make our builder beefier since we're on a beefy machine.
        virtualisation = {
          cores = 6;
          darwin-builder = {
            diskSize = 100 * 1024; # 100GB
            memorySize = 32 * 1024; # 32GB
          };
        };

        # Add some common debugging tools we can see whats up.
        environment.systemPackages = [
          pkgs.htop
        ];
      });
    };
    settings = {
      # Build performance settings
      cores = 0;  # Use all available cores for each build
      max-jobs = "auto";  # Auto-detect optimal number of parallel jobs

      experimental-features = [
        "nix-command"
        "flakes"
        "extra-platforms = aarch64-darwin x86_64-darwin"
        "external-builders"
      ];
      external-builders = [
        {
          systems = ["aarch64-linux" "x86_64-linux"];
          program = "/usr/local/bin/determinate-nixd";
          args = ["builder"];
        }
      ];
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

  # zsh is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    # Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    # End Nix
  '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    # Nix
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix
  '';

  environment.shells = with pkgs; [bashInteractive zsh fish];
  environment.systemPackages = with pkgs; [
    luajitPackages.tl
    libvterm-neovim
    cachix
    unixtools.netstat
    tailscale
  ];

  # Fonts
  fonts.packages = with pkgs; [
    fira-code
    font-awesome_5
    jetbrains-mono
    intel-one-mono
    nerd-fonts.symbols-only # symbols icon only
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    powerline-fonts
  ];

  services.tailscale.enable = true;
}
