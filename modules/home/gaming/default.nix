{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.gaming = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable gaming
      '';
    };
  };

  imports = [
    ./minecraft.nix
    ./skyrimvr.nix
  ];
}
