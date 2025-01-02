{
  config,
  lib,
  pkgs,
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
      pkgs.zigpkgs.master
      pkgs.zls
    ];
  };
}
