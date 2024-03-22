{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming
    themes.url = "github:RGBCube/ThemeNix";

    # Other packages
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = inputs: let
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "curtbushko";
        meta = {
          name = "curtbushko";
          title = "Custom Flake";
        };
      };
    };
  in
    lib.mkFlake {
      channels-config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          # "python-2.7.18.6"
          "electron-25.9.0"
        ];
      };

      overlays = with inputs; [
        zig.overlays.default
      ];

      systems.modules.darwin = with inputs; [
        home-manager.darwinModules.home-manager
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
      ];
    };
}
