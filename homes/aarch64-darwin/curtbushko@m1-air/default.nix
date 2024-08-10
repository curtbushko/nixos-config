{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  home, # The home architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format, # A normalized name for the home target (eg. `home`).
  virtual, # A boolean to determine whether this home is a virtual target using nixos-generators.
  host, # The host name for this home.
  # All other arguments come from the home home.
  config,
  ...
}: {
  home.stateVersion = "18.09";

  # Let home manager manage itself
  programs.home-manager.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-dark-medium;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.cargo
    pkgs.zigpkgs.master

    # Darwin only
    pkgs.cachix
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    TERM = "xterm-256color";
  };

  imports = [
    inputs.nix-colors.homeManagerModules.default
    inputs.sops-nix.homeManagerModules.sops
    ../../../modules/home/git
    ../../../modules/home/go
    ../../../modules/home/neovim
    ../../../modules/home/shells
    ../../../modules/home/terminals
    ../../../modules/home/tools
    ../../../modules/home/scripts
  ];
}
