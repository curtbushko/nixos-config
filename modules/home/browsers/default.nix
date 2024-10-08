{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    ./firefox.nix
  ];

  home.packages =
    [
    ]
    ++ (lib.optionals isLinux [
      inputs.zen-browser.packages.${system}.default
    ]);
}
