{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.gaming;
in {
  imports = [
    inputs.minecraft-servers.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    # Enable the minecraft-servers module for Prism Launcher setup
    programs.minecraft-servers = {
      enable = true;
      # Pre-configure the D&J server in the multiplayer menu
      serverEntries = [
        { name = "D&J Server (gamingrig)"; ip = "gamingrig:25565"; }
      ];
    };

    home.packages = with pkgs; [
      vulkan-loader
      glfw
      packwiz
    ];
  };
}
