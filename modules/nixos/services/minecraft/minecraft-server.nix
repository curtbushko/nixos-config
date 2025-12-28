{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.minecraft;

  # Packwiz modpack configuration
  # Currently using local modpack directory for development
  #
  # To use fetchPackwizModpack with GitHub (recommended once ready):
  # 1. Commit the modpack directory to git and push to GitHub
  # 2. Get a stable URL to pack.toml using a git commit hash:
  #    https://raw.githubusercontent.com/curtbushko/nixos-config/<COMMIT>/modules/nixos/services/minecraft/modpack/pack.toml
  # 3. Replace the modpack definition below with:
  #    modpack = pkgs.fetchPackwizModpack {
  #      url = "https://raw.githubusercontent.com/...";
  #      packHash = "sha256-0000000000000000000000000000000000000000000=";
  #    };
  # 4. Build the config - Nix will show the correct packHash in the error message
  # 5. Update packHash with the value from the error

  # Simple local modpack for development
  # This builds mods from the packwiz manifest without using fetchPackwizModpack
  modpack = pkgs.linkFarmFromDrvs "modpack-mods" [
    # Fabric API
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/oIVA3FbL/fabric-api-0.100.4%2B1.21.jar";
      sha512 = "CEle0tUC/gFxn+VfSf8LEG/duKkuGxe7drT/FZCjyba27WAcsqN83guzE5wsq/AFP+LdPWzojSZkgM80mWwLHg==";
      name = "fabric-api-0.100.4+1.21.jar";
    })
    # Add more mods here by copying entries from modpack/mods/*.pw.toml files
  ];
in {
  config = mkIf cfg.enable {
    services.minecraft-servers = {
      enable = true;
      eula = true;
      dataDir = "/var/lib/minecraft";

      servers.main = {
        enable = true;
        # Using Fabric server for mod support
        package = pkgs.fabricServers.fabric-1_21;
        openFirewall = true;
        jvmOpts = "-Xms2048m -Xmx6656m";

        serverProperties = {
          difficulty = "hard";
          gamemode = "survival";
          max-players = 3;
          view-distance = 64;
          simulation-distance = 8;
          motd = "D&J Minecraft Server";
          white-list = true;
        };

        whitelist = {
          Trospar = "79995c56-739b-4e4d-a6a7-c6b15781565d";
          PumpkinStigen = "5601a49d-1242-41f3-aaf5-13a995617132";
        };

        # Mods configuration using modpack
        symlinks = {
          "mods" = modpack;
        };
      };
    };
  };
}
