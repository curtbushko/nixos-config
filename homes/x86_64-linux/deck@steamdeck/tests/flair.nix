let
  flake = builtins.getFlake (toString ../../../..);
  config = flake.homeConfigurations."deck@steamdeck".config;
  flair = flake.inputs.flair.packages.x86_64-linux.default;
in
  assert builtins.elem (toString flair) (map toString config.home.packages);
  assert !config.stylix.targets.kde.enable;
  assert !config.stylix.targets.gtk.enable; true
