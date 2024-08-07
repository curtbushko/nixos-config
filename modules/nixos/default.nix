{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./dbus.nix
    ./fonts.nix
    ./pipewire.nix
    ./cachix.nix
    #./cuda.nix
    ./minecraft-server.nix
    ./sops.nix
    ./syncthing.nix
  ];
}
