{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf mkMerge;
  cfg = config.curtbushko.services.minecraft;

  # Shared whitelist for both servers
  whitelist = ''
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
  '';
in {
  options.curtbushko.services.minecraft = {
    dj-server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the dj-server Minecraft server
        '';
      };
    };
    homestead = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the homestead Minecraft server
        '';
      };
    };
  };

  config = mkMerge [
    # dj-server configuration
    (mkIf cfg.dj-server.enable {
      virtualisation.docker.enable = true;

      virtualisation.oci-containers = {
        backend = "docker";

        containers.minecraft-dj-server = {
          image = "ghcr.io/curtbushko/minecraft-servers/dj-server:latest";
          autoStart = true;

          volumes = [
            "/var/lib/minecraft-dj-server:/data"
          ];

          ports = [
            "25565:25565/tcp"
          ];
        };
      };

      systemd.services.docker-minecraft-dj-server = {
        preStart = ''
          mkdir -p /var/lib/minecraft-dj-server
          # Clear mods directory so packwiz can manage it cleanly
          # This prevents client/server mod mismatches from leftover mods
          if [ -d /var/lib/minecraft-dj-server/mods ]; then
            rm -rf /var/lib/minecraft-dj-server/mods
          fi
          cat > /var/lib/minecraft-dj-server/whitelist.json <<'EOF'
          ${whitelist}
          EOF
        '';
      };

      networking.firewall.allowedTCPPorts = [ 25565 ];
    })

    # homestead configuration
    (mkIf cfg.homestead.enable {
      virtualisation.docker.enable = true;

      virtualisation.oci-containers = {
        backend = "docker";

        containers.minecraft-homestead = {
          image = "ghcr.io/curtbushko/minecraft-servers/homestead:latest";
          autoStart = true;

          volumes = [
            "/var/lib/minecraft-homestead:/data"
          ];

          ports = [
            "25566:25565/tcp"
          ];
        };
      };

      systemd.services.docker-minecraft-homestead = {
        preStart = ''
          mkdir -p /var/lib/minecraft-homestead
          # Clear mods directory so packwiz can manage it cleanly
          # This prevents client/server mod mismatches from leftover mods
          if [ -d /var/lib/minecraft-homestead/mods ]; then
            rm -rf /var/lib/minecraft-homestead/mods
          fi
          cat > /var/lib/minecraft-homestead/whitelist.json <<'EOF'
          ${whitelist}
          EOF
        '';
      };

      networking.firewall.allowedTCPPorts = [ 25566 ];
    })
  ];
}
