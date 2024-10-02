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
    ./llm.nix
    #./cuda.nix
    ./minecraft-server.nix
    ./qt.nix
    ./sops.nix
    ./syncthing.nix
  ];
}
