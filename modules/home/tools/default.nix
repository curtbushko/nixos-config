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
    ./atuin.nix
    ./bat.nix
    ./direnv.nix
    ./llm.nix
  ];

  home.packages =
    [
      pkgs.age
      pkgs.alejandra
      pkgs.asciinema
      pkgs.bottom
      pkgs.btop
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
      pkgs.nil # language server
      pkgs.nixd #language server for nix
      pkgs.nodejs_22
      pkgs.ranger
      pkgs.ripgrep
      pkgs.sops
      pkgs.stylua
      pkgs.tree
      pkgs.watch
      pkgs.watchexec
      pkgs.wakeonlan
      pkgs.wget
      pkgs.yazi
      pkgs.yt-dlp
      pkgs.unzip
      pkgs.zoxide
      pkgs.zstd
    ]
    ++ (lib.optionals isDarwin [
      pkgs.cachix
    ])
    ++ (lib.optionals isLinux [
      #pkgs.rofi-firefox-wrapper
      pkgs.ddcutil
      pkgs.zathura
      pkgs.lsof
      pkgs.mpv
      pkgs.remmina # remote desktop client
    ]);
}
