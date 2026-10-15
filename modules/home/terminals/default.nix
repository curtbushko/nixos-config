{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.ns.terminals = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Ghostty, Rex (macOS), Starship, and tmux
      '';
    };
  };

  imports = [
    ./alacritty.nix
    ./ghostty.nix
    ./rex.nix
    ./starship.nix
    ./tmux.nix
  ];
}
