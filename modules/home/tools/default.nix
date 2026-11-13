{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.tools;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  ytDlpPkgs = inputs.yt-dlp-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ./bat.nix
    ./direnv.nix
    ./exercism.nix
    ./mpv.nix
    ./notesmd-cli.nix
    ./television
    ./worktrunk
    ./yazi.nix
  ];
  options.ns.tools = {
    nil.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install nil when tools are enabled";
    };
    lima.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install Lima when tools are enabled";
    };
    remmina.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install Remmina when tools are enabled on Linux";
    };
    zathura.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install Zathura when tools are enabled on Linux";
    };
    yt-dlp.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install yt-dlp when tools are enabled";
    };
    sshuttle.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install sshuttle when tools are enabled";
    };
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tools
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.worktrunk.package = inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default;

    home.packages =
      [
        pkgs.age
        pkgs.alejandra
        pkgs.asciinema
        pkgs.bats
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
        pkgs.miller
        pkgs.mutagen
        pkgs.nixd #language server for nix
        pkgs.nodejs
        pkgs.presenterm
        pkgs.ripgrep
        pkgs.shellcheck
        pkgs.shfmt
        pkgs.stylua
        pkgs.go-task
        pkgs.tree
        pkgs.watch
        pkgs.watchexec
        pkgs.wakeonlan
        pkgs.wget
        pkgs.yq-go
        pkgs.unison
        pkgs.unzip
        pkgs.zoxide
        pkgs.zstd
      ]
      ++ (lib.optionals cfg.nil.enable [pkgs.nil])
      ++ (lib.optionals cfg.lima.enable [pkgs.lima])
      ++ (lib.optionals (isLinux && cfg.remmina.enable) [pkgs.remmina])
      ++ (lib.optionals (isLinux && cfg.zathura.enable) [pkgs.zathura])
      ++ (lib.optionals cfg.yt-dlp.enable [ytDlpPkgs.yt-dlp])
      ++ (lib.optionals cfg.sshuttle.enable [pkgs.sshuttle])
      ++ (lib.optionals isDarwin [
        pkgs.cachix
      ])
      ++ (lib.optionals isLinux [
        #pkgs.rofi-firefox-wrapper
        pkgs.d2
        pkgs.ddcutil
        pkgs.lsof
      ]);
  };
}
