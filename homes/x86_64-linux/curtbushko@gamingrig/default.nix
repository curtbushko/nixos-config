{
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  system,
  ...
}: {
  home.stateVersion = "18.09";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;
  #xdg.configFile = {
  #  "ghostty/config".text = builtins.readFile ./ghostty.config;
  #};
  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.cargo
    pkgs.crawl
    pkgs.crawlTiles

    pkgs.zigpkgs.master
    pkgs.zls

    # Darwin only
    pkgs.cachix
    pkgs.tailscale
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
    inputs.stylix.homeManagerModules.stylix
    ../../../modules/home/browsers
    ../../../modules/home/gamedev
    ../../../modules/home/git
    ../../../modules/home/go
    ../../../modules/home/secrets
    ../../../modules/home/shells
    ../../../modules/home/terminals
    ../../../modules/home/tools
    ../../../modules/home/wm
    inputs.sops-nix.homeManagerModules.sops
  ];
}
