{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.hardware.cpu = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS services related to CPUs
      '';
    };
  };

  imports = [
    ./cooling.nix
  ];
}
