{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #ghostty = {
    #  url = "github:clo4/ghostty-hm-module";
    #};

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1"; # follows development branch of hyprland
    };

    hypr-dynamic-cursors = {
        url = "github:VirtCode/hypr-dynamic-cursors";
        inputs.hyprland.follows = "hyprland"; # to make sure that the plugin is built for the correct version of hyprland
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprlock.url = "github:hyprwm/hyprlock";

    hyprpaper.url = "github:hyprwm/hyprpaper";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";

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
        cudaSupport = true;
        cudaCapabilities = ["7.2 "];
        cudaEnableForwardCompat = false;
        allowUnsupportedSystem = true;
        allowBroken = true;
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
        nix-colors.homeManagerModules.default
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
      ];
    };
}
