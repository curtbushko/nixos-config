{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.asciinema
    pkgs.cargo
    pkgs.crawl
    pkgs.crawlTiles
    pkgs.eza
    pkgs.fd
    pkgs.fzf
    pkgs.gnused
    pkgs.htop
    pkgs.jq
    pkgs.kubectl
    pkgs.python3
    pkgs.ranger
    pkgs.ripgrep
    pkgs.tree
    pkgs.watch
    pkgs.yt-dlp
    pkgs.zoxide

    pkgs.zigpkgs.master

    # Darwin only
    pkgs.cachix
    pkgs.tailscale
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
    PATH = "$HOME/scripts:$PATH";
    TERM = "xterm-256color";
  };


  imports = [
    #nix-colors.homeManagerModules.default
    ../../modules/bat.nix
    ../../modules/git
    ../../modules/go
    ../../modules/neovim
    ../../modules/shells
    ../../modules/terminals
  ];

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------
 
  programs.direnv = {
    enable = true;
    config = {
      whitelist = {
        prefix = [
          "$HOME/code/go/src/github.com/hashicorp"
          "$HOME/code/go/src/github.com/mitchellh"
          "$HOME/code/go/src/github.com/curtbushko"
        ];

        exact = [ "$HOME/.envrc" ];
      };
    };
  };
}
