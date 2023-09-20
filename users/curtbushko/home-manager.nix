#colorScheme = nix-colors.colorSchemes.tokyo-night-terminal-dark;
{ config, lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

in
{
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";
  home.enableNixpkgsReleaseCheck = false;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.asciinema
    pkgs.asdf
    pkgs.bashInteractive
    pkgs.bats
    pkgs.bitwarden-cli
    pkgs.coreutils
    pkgs.cmake
    pkgs.curl
    pkgs.delve
    pkgs.delta
    pkgs.direnv
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.glow
    pkgs.gofumpt
    pkgs.golangci-lint
    pkgs.gopls
    pkgs.gotestsum
    pkgs.gox
    pkgs.hey
    pkgs.htop
    pkgs.jq
    pkgs.kind
    pkgs.krew
    pkgs.kubectx
    pkgs.kubectl
    pkgs.kustomize
    pkgs.lazygit
    pkgs.lua
    pkgs.nil
    pkgs.nix-bash-completions
    pkgs.nixfmt
    pkgs.openresty
    pkgs.protobuf
    pkgs.protoc-gen-go
    pkgs.yq
    pkgs.ripgrep
    pkgs.shellcheck
    pkgs.stern
    pkgs.tree
    pkgs.watch
    pkgs.watchexec
    pkgs.wget
    pkgs.yarn
    pkgs.yt-dlp
    pkgs.zoxide
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
  };


  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      color = "always";
      style = "numbers,changes";
      italic-text = "always";
    };
  };

  programs.git = {
    enable = true;
    userName = "Curt Bushko";
    userEmail = "cbushko@gmail.com";
    ignores = [ "*~" ".DS_Store" ".direnv" ".env" ".rgignore" ];
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull = {
        ff = "only";
      };
      url."ssh://git@github.com".insteadOf = "https://github.com";
      branch.autosetuprebase = "always";
      color.ui = true;
      github.user = "curtbushko";
      push.default = "tracking";
    };
    delta = {
      enable = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        decorations = {
          commit-decoration-style = "blue ol";
          hunk-header-decoration-style = "blue box";
          hunk-header-file-style = "blue";
          hunk-header-line-number-style = "#ff9e64";
          hunk-header-style = "file line-number";
          file-decoration-style = "none";
          file-style = "bold yellow ul";
          minus-style = "red";
          minus-emph-style = "#ff5370";
          plus-style = "green";
          zero-style = "white";
          commit-style = "raw";
          line-numbers-minus-style = "red";
          line-numbers-plus-style = "green";
          line-numbers-zero-style = "purple";
        };
        features = "decorations, syntax-theme, line-numbers";
        whitespace-error-style = "22 reverse";
      };
    };
    aliases = {
      addp = "add -p";
      al = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /'";
      as = "update-index --assume-unchanged";
      br = "checkout";
      ci = "commit";
      co = "checkout";
      cp = "cherry-pick";
      di = "diff";
      dif = "diff";
      diffs = "diff --cached";
      gerp = "grep";
      grpe = "grep";
      hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
      nas = "update-index --no-assume-unchanged";
      pub = "push -u origin HEAD";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      pullf = "pull --ff-only";
      root = "rev-parse --show-toplevel";
      shoe = "show";
      st = "status";
    };
  };

  programs.go = {
    enable = true;
    goPrivate = [ "github.com/curtbushko" "github.com/mitchellh" "github.com/hashicorp" ];
  };

  # programs.zsh = {
  #   enable = true;
  #
  #   initExtra = builtins.readFile ./zshrc;
  # };
}
