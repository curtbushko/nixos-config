{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.shells;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.curtbushko.shells = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable shells
      '';
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      COLORTERM = "truecolor";
    };
  };

  imports = [
    ./bash.nix
    ./zsh.nix
    ./nushell.nix
  ];
}
