{
  pkgs,
  inputs,
  system,
  ...
}: {
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "18.09";

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.cargo
    pkgs.zigpkgs.master

    # Darwin only
    pkgs.cachix
    inputs.neovim.packages.${system}.default
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
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeManagerModules.stylix
    ../../../modules/home/styles
    ../../../modules/home/git
    ../../../modules/home/go
    #../../../modules/home/neovim
    ../../../modules/home/shells
    ../../../modules/home/terminals
    ../../../modules/home/tools
    ../../../modules/home/scripts
  ];
}
