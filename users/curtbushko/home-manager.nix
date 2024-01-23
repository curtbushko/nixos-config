{ inputs, ... }:

{ config, lib, pkgs, ... }:

let

  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" (if isDarwin then ''
    sh -c 'col -bx | bat -l man -p'
  '' else ''
    cat "$1" | col -bx | bat --language man --style plain
  ''));
in
{
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.configFile = {
    "ghostty/config".text = builtins.readFile ./ghostty.config;
  };

  #xdg.configFile."./nvim/lazyvim.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nvim/lazyvim.json";
  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.asciinema
    pkgs.cargo
    pkgs.exa
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.gnused
    pkgs.helm
    pkgs.htop
    pkgs.jq
    pkgs.kubectl
    pkgs.lazygit
    pkgs.python3
    pkgs.ranger
    pkgs.ripgrep
    pkgs.tree
    pkgs.watch
    pkgs.yt-dlp
    pkgs.zoxide

    pkgs.gopls
    pkgs.golangci-lint
    pkgs.zigpkgs.master

  ] ++ (lib.optionals isDarwin [
    # This is automatically setup on Linux
    pkgs.cachix
    pkgs.tailscale
  ]) ++ (lib.optionals (isLinux) [
    pkgs.chromium
    pkgs.firefox
    pkgs.rofi
    pkgs.zathura
    pkgs.xfce.xfce4-terminal
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };


  imports = [
    #nix-colors.homeManagerModules.default
    ./bat.nix
    ./git.nix
    ./go.nix
    ./neovim.nix
    ./starship.nix
    ./zellij.nix
    ./zsh.nix
  ];

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------
  programs.alacritty = {
    settings = {
      env.TERM = "xterm-256color";

      key_bindings = [
        { key = "K"; mods = "Command"; chars = "ClearHistory"; }
        { key = "V"; mods = "Command"; action = "Paste"; }
        { key = "C"; mods = "Command"; action = "Copy"; }
        { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
        { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
      ];
    };
  };

  programs.bash = {
    enable = true;
    shellOptions = [ ];
    historyControl = [ "ignoredups" "ignorespace" ];
  };
 
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


  #TODO Add tmux

  programs.kitty = {
    extraConfig = builtins.readFile ./kitty;
  };
}
