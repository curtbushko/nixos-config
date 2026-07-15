{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.shells;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.ns.shells = {
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
      PODMAN_NO_EMOJI = "1";
    };
  };

  imports = [
    ./bash.nix
    ./zsh.nix
  ];
}
