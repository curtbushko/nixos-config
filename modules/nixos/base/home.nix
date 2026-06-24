{inputs, ...}: {
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    sharedModules = [
      inputs.stylix.homeModules.stylix
    ];
  };
}
