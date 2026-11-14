let
  flake = builtins.getFlake (toString ../../../..);
  config = flake.homeConfigurations."deck@steamdeck".config;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  rex = builtins.head (builtins.filter (package: (package.pname or "") == "rex") config.home.packages);
in
  pkgs.buildEnv {
    name = "steamdeck-rex-profile-check";
    paths = [rex config.programs.rex-whichkey.package];
  }
