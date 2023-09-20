{
    description = "Home Manager configuration";

    inputs = {

        nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        darwin = {
            url = "github:LnL7/nix-darwin";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nix-colors.url = "github:misterio77/nix-colors";
    };

  outputs = { self, nixpkgs, home-manager, darwin, nix-colors, ... }@inputs: let
    mkDarwin = import ./lib/mkdarwin.nix;

  in {
    darwinConfigurations.m1-air = mkDarwin "m1-air" {
      inherit darwin nixpkgs home-manager nix-colors;
      system = "aarch64-darwin";
      user   = "curtbushko";
    };
  };
}
