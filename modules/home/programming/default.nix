{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.programming;
in {
  options.ns.programming = {
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
      package = pkgs.go_1_26.overrideAttrs (_: {
        version = "1.26.8";
        src = pkgs.fetchurl {
          url = "https://go.dev/dl/go1.26.8.src.tar.gz";
          hash = "sha256-Tjm5jkL5RvoFrIvFtxh335fb23y7Gnd7VBZnrXEX/S4=";
        };
      });
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
