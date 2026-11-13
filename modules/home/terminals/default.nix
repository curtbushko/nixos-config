{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.ns.terminals = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Ghostty configuration, Rex (macOS), and Starship
      '';
    };
  };

  imports = [
    ./ghostty.nix
    ./rex.nix
    ./starship.nix
  ];
}
