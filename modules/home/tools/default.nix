{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    ./bat.nix
    ./direnv.nix
  ];

  home.packages =
    [
      pkgs.alejandra
      pkgs.asciinema
      pkgs.bottom
      pkgs.difftastic
      pkgs.curl
      pkgs.eza
      pkgs.fd
      pkgs.fzf
      pkgs.gnused
      pkgs.gum
      pkgs.htop
      pkgs.jq
      pkgs.kubectl
      pkgs.kind
      pkgs.lsd
      pkgs.python3
      pkgs.ranger
      pkgs.ripgrep
      pkgs.tree
      pkgs.watch
      pkgs.watchexec
      pkgs.wakeonlan
      pkgs.yazi
      pkgs.yt-dlp
      pkgs.zoxide
    ]
    ++ (lib.optionals isDarwin [
      pkgs.cachix
      pkgs.tailscale
    ])
    ++ (lib.optionals isLinux [
      #pkgs.rofi-firefox-wrapper
      pkgs.ddcutil
      pkgs.zathura
      pkgs.lsof
      pkgs.remmina # remote desktop client
    ]);
}
