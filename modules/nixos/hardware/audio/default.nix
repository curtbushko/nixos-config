{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.ns.hardware.audio = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS windows manager services
      '';
    };
  };

  imports = [
    ./dbus.nix
    ./pipewire.nix
  ];
}
