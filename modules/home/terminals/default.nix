{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.terminals = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable ghostty, zellij, starship, etc
      '';
    };
  };

  imports = [
    ./alacritty.nix
    ./ghostty.nix
    ./starship.nix
    ./tmux.nix
  ];
}
