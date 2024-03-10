{ lib, pkgs, config, osConfig ? { }, format ? "unknown", ... }:

with lib.mynamespace;
{
  mynamespace = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };
  };

  home.sessionPath = [
    "$HOME/bin"
  ];

  home.stateVersion = "18.09";
}
