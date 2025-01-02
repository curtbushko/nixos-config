{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.services.wm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS windows manager services
      '';
    };
  };

  imports = [
    ./fonts.nix
    ./qt.nix
    ./wayland.nix
  ];
}
