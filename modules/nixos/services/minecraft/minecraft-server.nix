{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.minecraft;

  # Path to packwiz modpack directory
  modpackPath = ./modpack;

  # Function to parse a .pw.toml file and return fetchurl derivation
  # Returns null for client-only mods
  parseModToml = tomlFile: let
    tomlContent = builtins.fromTOML (builtins.readFile tomlFile);
    # Only include mods that are for server or both sides
    isServerMod = tomlContent.side == "both" || tomlContent.side == "server";
    # Build hash attribute based on hash-format in TOML
    hashFormat = tomlContent.download.hash-format;
    hashValue = tomlContent.download.hash;
    hashAttrs =
      if hashFormat == "sha512"
      then {sha512 = hashValue;}
      else if hashFormat == "sha256"
      then {sha256 = hashValue;}
      else if hashFormat == "sha1"
      then {sha1 = hashValue;}
      else throw "Unsupported hash format: ${hashFormat} in ${tomlFile}";
  in
    if isServerMod
    then
      pkgs.fetchurl ({
          url = tomlContent.download.url;
          name = tomlContent.filename;
        }
        // hashAttrs)
    else null;

  # Get all .pw.toml files from the modpack/mods directory
  modFiles = builtins.attrNames (builtins.readDir (modpackPath + "/mods"));

  # Parse all mod files and filter out nulls (client-only mods)
  serverMods = builtins.filter (mod: mod != null) (
    map (file: parseModToml (modpackPath + "/mods/${file}"))
    (builtins.filter (file: lib.hasSuffix ".pw.toml" file) modFiles)
  );

  # Modpack configuration using linkFarmFromDrvs
  # Mods are automatically loaded from packwiz .pw.toml files
  modpack = pkgs.linkFarmFromDrvs "modpack-mods" serverMods;

  # Resource packs configuration
  resourcepacks = pkgs.linkFarmFromDrvs "resourcepacks" [
    # FreshAnimations_v1.10.3.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/50dA9Sha/versions/F9QwVhGH/FreshAnimations_v1.10.3.zip";
      sha512 = "713dd4e810a59d84844e25fa5fb3e36c83ac2e197d5259e16b61d4b4899f1a3f8bacdd4d4e5d0f5cde9a3497fad5e50ccea0c6270898f53f802e340e3fb3e73f";
      name = "FreshAnimations_v1.10.3.zip";
    })
    # MoreMobVariants_FreshAnimations_1.3.1-1.9.2.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/ZrnmXWf6/versions/uIOGuHMy/MoreMobVariants_FreshAnimations_1.3.1-1.9.2.zip";
      sha512 = "262573dd4bc91133d6d5c7abb751345533b82c1d34f694ee555c50089720a90b1aa345300a1fea216aa9aa08a8e58f04b5a2e6a57a75d6027cddfd2a96afa962";
      name = "MoreMobVariants_FreshAnimations_1.3.1-1.9.2.zip";
    })
    # Dramatic_Skys_Demo_1.5.3.36.2.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2YyNMled/versions/Y8mjFzcP/Dramatic%20Skys%20Demo%201.5.3.36.2.zip";
      sha512 = "00f62d91a67bc00f83ff5be65d11cdb71f2386583dd4fec26f036b2fc400b4a37a6c404a237bf4dfd479da0230c28125a4dec86799dc0cc691d5bde863bc30a1";
      name = "Dramatic_Skys_Demo_1.5.3.36.2.zip";
    })
    # Better-Leaves-9.4.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/uvpymuxq/versions/JW14JsXq/Better-Leaves-9.4.zip";
      sha512 = "d6969d044a6e48468b3637e29e0d6afa9af4618bf20bf28db7e3c588ea6bbd2f3a4cf9f154524249fe154b4ff8fb7ccc8c59099fd9ccc6d6bec714ae56ea2102";
      name = "Better-Leaves-9.4.zip";
    })
    # Fresh_Moves_v3.1.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/slufHzC2/versions/lHNQh6Gv/-1.21.2%20Fresh%20Moves%20v3.1%20%28No%20Animated%20Eyes%29.zip";
      sha512 = "ac0cb4207d3b20fd94e899b63e7a29cf7e1836cb711181f94d72be5ecb8454293a87135998f7298628dc88b2cb79d59a9be2ea1cd9ebfb24ef5d1e2a16e4361c";
      name = "Fresh_Moves_v3.1.zip";
    })
    # LowOnFire_1.21.3.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/RRxvWKNC/versions/QL8e10aI/LowOnFire%201.21.3.zip";
      sha512 = "2a6bcdd6963996af35474fc12cd4a57163d1435d2f8b61383eb269ca66297e80d6b687343fc7f151d4111719e05ae90020c3b4d1075bf9e1c33765cc3f68748f";
      name = "LowOnFire_1.21.3.zip";
    })
    # FA+All_Extensions-v1.7.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YAVTU8mK/versions/hGa4E44T/FA%2BAll_Extensions-v1.7.zip";
      sha512 = "4c7e8ead077cf2da3005e23a1928417374be8f27513fe4ec24c49f8eabd0305e3e57cba073228b4f851b7035d491f0f64c37dd28f3a5fb315a5d05c930233a89";
      name = "FA_All_Extensions-v1.7.zip";
    })
    # cubic-sun-moon-v1.8.1a.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/g4bSYbrU/versions/3svw5AHq/cubic-sun-moon-v1.8.1a.zip";
      sha512 = "1112fd0411fb739b3b047d9ced2d5d85d35a10e9a44ae277721dcfe490b6ec5cdd64e62a0fce5e96a309ec2153d66c542fce3633195841f665bf424b7b1bf749";
      name = "cubic-sun-moon-v1.8.1a.zip";
    })
    # Low_Shield.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/CZrLuVQo/versions/bDbgSHEM/Low%20Shield.zip";
      sha512 = "aac76c9f32d87e2aae42a77f39d10dc978d4095017f6d85eb541b357e46a791e35b9ae65c5fece84ae34fe464b9ed26a1532c805dda617100ac8a1eef320114e";
      name = "Low_Shield.zip";
    })
    # Fresh_Food_1.1.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/UoLAbzII/versions/CRI4mlJe/Fresh%20Food%201.1%20-%201.20.1-1.21.1.zip";
      sha512 = "7079b9d28b4d28db27409e2df4240fb9c43b737386ab133498f7a7b9cd13efabf2c369d5f0a621892132d77b6c499dbf749a7687fe055e0f905e72cdbed945a1";
      name = "Fresh_Food_1.1.zip";
    })
  ];

  # Shader packs configuration (requires Iris mod)
  shaderpacks = pkgs.linkFarmFromDrvs "shaderpacks" [
    # ComplementaryReimagined_r5.6.1.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HVnmMxH1/versions/OfRF7dTR/ComplementaryReimagined_r5.6.1.zip";
      sha512 = "01426ce261df8a4fa99366efe30e98656bac43ac8a71db1265edb0b49c5e4abb9ada09d6877a6c1d728244fde202f57118339d3a0503a1cbc8af88325c8d4f5a";
      name = "ComplementaryReimagined_r5.6.1.zip";
    })
  ];

  # Datapacks configuration
  # Note: These are kept as individual fetchurl derivations
  # They will be copied (not symlinked) to the world directory in preStart
  tectonicDatapack = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/lWDHr9jE/versions/VfuqmXvF/tectonic-datapack-3.0.18.zip";
    sha512 = "3de178cc019f481d86511d66c579317a1277167685d7886707ae591f25cc910cb2d5550ef77d69c2d35b0acdb2c67b05f7ef014c45a9feda2867281227d85e81";
    name = "tectonic-datapack-3.0.18.zip";
  };

in {
  config = mkIf cfg.enable {
    # Enable Docker for running Minecraft server
    virtualisation.docker.enable = true;

    # Run Minecraft NeoForge server in Docker using itzg/minecraft-server
    virtualisation.oci-containers = {
      backend = "docker";

      containers.minecraft-server = {
        image = "itzg/minecraft-server:java21";
        autoStart = true;

        environment = {
          # Server type and version
          TYPE = "NEOFORGE";
          VERSION = "1.21.1";
          NEOFORGE_VERSION = "21.1.217";

          # Accept EULA
          EULA = "TRUE";

          # Server properties
          DIFFICULTY = "hard";
          MODE = "survival";
          MAX_PLAYERS = "3";
          VIEW_DISTANCE = "64";
          SIMULATION_DISTANCE = "8";
          MOTD = "D&J Minecraft Server";
          ENABLE_WHITELIST = "TRUE";

          # Memory settings
          MEMORY = "6G";
          INIT_MEMORY = "2G";

          # JVM options
          JVM_XX_OPTS = "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200";

          # Allow symlinks for mod directories
          ALLOW_FLIGHT = "FALSE";

          # Disable built-in mod download (we manage mods via packwiz)
          REMOVE_OLD_MODS = "FALSE";
        };

        volumes = [
          # Persistent world data
          "/var/lib/minecraft-server:/data"

          # Mount packwiz-managed mods (read-only)
          "${modpack}:/data/mods:ro"

          # Mount resourcepacks (read-only)
          "${resourcepacks}:/data/resourcepacks:ro"

          # Mount shaderpacks (read-only)
          "${shaderpacks}:/data/shaderpacks:ro"

          # Note: datapacks are copied in preStart, not mounted as volume
          # to avoid symlink security issues with Minecraft
        ];

        ports = [
          "25565:25565/tcp"  # Minecraft server port
        ];
      };
    };

    # Create whitelist.json and copy datapacks before container starts
    systemd.services.docker-minecraft-server = {
      preStart = ''
        mkdir -p /var/lib/minecraft-server

        # Create whitelist.json
        cat > /var/lib/minecraft-server/whitelist.json <<'EOF'
        [
          {
            "uuid": "79995c56-739b-4e4d-a6a7-c6b15781565d",
            "name": "Trospar"
          },
          {
            "uuid": "5601a49d-1242-41f3-aaf5-13a995617132",
            "name": "PumpkinStigen"
          }
        ]
        EOF

        # Copy datapacks (cannot use symlinks due to Minecraft security validation)
        # Note: world directory may not exist yet on first run
        # The Docker container will create it, and we'll update datapacks on subsequent starts
        if [ -d /var/lib/minecraft-server/world ]; then
          mkdir -p /var/lib/minecraft-server/world/datapacks

          # Remove any existing symlinks (from previous configuration)
          find /var/lib/minecraft-server/world/datapacks -type l -delete

          # Copy tectonic datapack (overwrite if exists to ensure updates)
          cp -f ${tectonicDatapack} /var/lib/minecraft-server/world/datapacks/tectonic-datapack-3.0.18.zip
        fi
      '';
    };

    # Open firewall for Minecraft
    networking.firewall.allowedTCPPorts = [ 25565 ];
  };
}
