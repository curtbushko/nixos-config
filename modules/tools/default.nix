{ config, lib, pkgs, ... }:
{
    imports = [
        ./bat.nix
        ./direnv.nix
    ];

  home.packages = [
    pkgs.asciinema
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

  ];


} 
