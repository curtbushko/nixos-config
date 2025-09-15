{
  config,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.programming;
in {
  options.curtbushko.programming = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable programming languages (go, rust, zig)
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.go = {
      enable = true;
    };
    home.packages = [
      pkgs.cargo
      pkgs.gopls
      pkgs.golangci-lint
      pkgs.gotestsum
      #pkgs.zigpkgs.master
      pkgs.zigpkgs."0.13.0"
      pkgs.zls
    ];
    # configure cargo so that it can download crates
    home.file = {
      ".cargo/config.toml" = {
        text = ''
          [net]
          git-fetch-with-cli = true   # use the `git` executable for git operations
        '';
      };
    };
  };
}
