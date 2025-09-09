{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.tools;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    ./atuin.nix
    ./bat.nix
    ./direnv.nix
    ./mpv.nix
    ./yazi.nix
  ];
  options.curtbushko.tools = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tools
      '';
    };
  };

  config = mkIf cfg.enable {
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
        pkgs.lsd
        pkgs.mutagen
        pkgs.nil # language server
        pkgs.nixd #language server for nix
        pkgs.nodejs_22
        pkgs.presenterm
        pkgs.ripgrep
        pkgs.stylua
        pkgs.sshuttle
        pkgs.tree
        pkgs.watch
        pkgs.watchexec
        pkgs.wakeonlan
        pkgs.wget
        pkgs.yt-dlp
        pkgs.unison
        pkgs.unzip
        pkgs.zoxide
        pkgs.zstd
        pkgs.presenterm
      ]
      ++ (lib.optionals isDarwin [
        pkgs.cachix
      ])
      ++ (lib.optionals isLinux [
        #pkgs.rofi-firefox-wrapper
        pkgs.ddcutil
        pkgs.zathura
        pkgs.lsof
        pkgs.remmina # remote desktop client
      ]);
  };
}
