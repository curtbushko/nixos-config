{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.services.minecraft;
in {
  options.curtbushko.services.minecraft = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS minecraft server
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable Docker for running Minecraft server
    virtualisation.docker.enable = true;

    # Run Minecraft server using pre-built Docker image from minecraft-servers repo
    # Image: ghcr.io/curtbushko/minecraft-servers/dj-server:latest
    virtualisation.oci-containers = {
      backend = "docker";

      containers.minecraft-server = {
        image = "ghcr.io/curtbushko/minecraft-servers/dj-server:latest";
        autoStart = true;

        volumes = [
          # Persistent world data
          "/var/lib/minecraft-server:/data"
        ];

        ports = [
          "25565:25565/tcp"
        ];
      };
    };

    # Create data directory and whitelist before container starts
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
      '';
    };

    # Open firewall for Minecraft
    networking.firewall.allowedTCPPorts = [ 25565 ];
  };
}
