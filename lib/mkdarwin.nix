# This function creates a nix-darwin system.
name: { darwin, nixpkgs, home-manager, system, user, nix-colors }:

darwin.lib.darwinSystem rec {
  inherit system;

  modules = [
    ../os/darwin.nix
    ../users/${user}/darwin.nix
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import ../users/${user}/home-manager.nix;
    }

    # We expose some extra arguments so that our modules can parameterize
    # better based on these values.
    {
      config._module.args = {
        currentSystemName = name;
        currentSystem = system;
      };
    }
  ];
}
