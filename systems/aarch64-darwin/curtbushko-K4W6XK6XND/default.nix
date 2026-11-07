{
  pkgs,
  inputs,
  ...
}: {
  ns.user.name = "curtbushko";
  nix.enable = false;
  system.stateVersion = 5;

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
      cores = 0; # Use all available cores for each build
      max-jobs = "auto"; # Auto-detect optimal number of parallel jobs

      # Parallel downloads for faster substitution
      http-connections = 128;
      max-substitution-jobs = 128;

      # Network optimization
      connect-timeout = 5;
      stalled-download-timeout = 30;
      download-attempts = 3;

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
    obsidian
  ];

  # Fonts
  fonts.packages = with pkgs; [
    fira-code
    font-awesome_5
    jetbrains-mono
    intel-one-mono
    nerd-fonts.symbols-only # symbols icon only
    nerd-fonts.fira-code
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.sauce-code-pro
    noto-fonts
    noto-fonts-color-emoji
    powerline-fonts
  ];
}
