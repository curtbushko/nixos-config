{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    minecraft-server = {
      image = "itzg/minecraft-server:java17";
      ports = [
        "25565:25565/tcp"
      ];
      volumes = [
        # Need to place non-distributable mods in ./downloads/mods
        # As of Update-10.0.0
        # - Neon Craft 2 v2.2: https://www.curseforge.com/minecraft/mc-mods/neon-craft-2-mod/files/3726051
        "/var/lib/minecraft/downloads:/downloads"
        "/var/lib/minecraft:/data"
      ];
      environment = {
        EULA = "true";
        MOD_PLATFORM = "AUTO_CURSEFORGE";
        CF_API_KEY = "$2a$10$hBHorcVy1x8ivmNTSfrOUeyCc/fNPmeq3UjgWerLEZ/0n6NmBpAw2"; # allocate from https://console.curseforge.com/
        CF_SLUG = "vault-hunters-1-18-2";
        CF_FILENAME_MATCHER = "3.14.3";
        MOTD = "J&D Vault Hunters";
        MEMORY = "8G"; # 4G for base server + 2G per player
        CF_EXCLUDE_MODS = "reauth";
        ALLOW_FLIGHT = "true";
        ENABLE_COMMAND_BLOCK = "true";
        MODE = "survival";
        DIFFICULTY = "normal";
        MAX_PLATERS = "3";
        VIEW_DISTANCE = "32";
        #WHITELIST_FILE = ;
      };
    };
  };
}
#  white-list.json = pkgs.writeTextFile {
#      name = "white-list.json";
#      text = ''{
#        Trospar = "79995c56-739b-4e4d-a6a7-c6b15781565d"
#        PumpkinStigen = "5601a49d-1242-41f3-aaf5-13a995617132"
#      }'';
#    };
#    services.minecraft-server = {
#        enable = true;
#        package = pkgs.minecraftServers.vanilla-1-18;
#        dataDir = "/var/lib/minecraft";
#        eula = true;
#        declarative = true;
#        jvmOpts = "-Xms2048m -Xmx6656m";
#        openFirewall = true;
#        serverProperties = {
#            difficulty = "normal";
#            gamemode = "survival";
#            max-players = 3;
#            view-distance = 32;
#            simulation-distance = 8;
#            motd = "D&J Minecraft Server";
#            white-list = true;
#        };
#        whitelist = {
#            Trospar = "79995c56-739b-4e4d-a6a7-c6b15781565d";
#            PumpkinStigen = "5601a49d-1242-41f3-aaf5-13a995617132";
#        };
#    };
#}

