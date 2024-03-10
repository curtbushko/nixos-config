{
  config,
  lib,
  ...
}: let
  inherit (lib) mkForce;
  inherit (lib.internal) enabled disabled;
in {
  my-namespace = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    home.stateVersion = "18.09";
  };
}
