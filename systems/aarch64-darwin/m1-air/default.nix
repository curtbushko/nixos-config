{
  config,
  pkgs,
  inputs,
  ...
}: {
  # We install Nix using a separate installer so we don't want nix-darwin
  # to manage it for us. This tells nix-darwin to just use whatever is running.
  nix.useDaemon = true;
  services.nix-daemon.enable = true;

  # Keep in async with vm-shared.nix. (todo: pull this out into a file)
  nix = {
    # We need to enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    settings = {
      trusted-public-keys = [
        nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
        cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      ];
      trusted-substituters = [
        https://nix-community.cachix.org
        https://cache.nixos.org
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
    tailscale
  ];

  # Fonts
  fonts.packages = with pkgs; [
    fira-code
    font-awesome_5
    jetbrains-mono
    intel-one-mono
    nerdfonts
    noto-fonts
    noto-fonts-extra
    noto-fonts-emoji
    powerline-fonts
  ];

  services.tailscale.enable = true;
}
