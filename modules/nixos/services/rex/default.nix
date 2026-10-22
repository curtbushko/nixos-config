{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ns.services.rex;
  renderer = pkgs.writeShellApplication {
    name = "rex-env-render";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = builtins.readFile ../../../home/scripts/rex-env-render;
  };
in {
  imports = [
    inputs.rex.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  options.ns.services.rex = {
    enable = lib.mkEnableOption "Rex login server with Tailscale and trusted LAN access";
    lanAddress = lib.mkOption {
      type = lib.types.str;
      default = "192.168.2.55";
      description = "Gamingrig's LAN IPv4 address; reserve it in DHCP.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (inputs.rex-whichkey.lib.mkPackage {inherit pkgs;})
    ];
    # The login server starts a personal server with this account's init.lua.
    home-manager.users.curtbushko.ns.terminals.rex.enable = true;

    sops.age.keyFile = "/home/curtbushko/.config/sops/age/keys.txt";
    # dotenv key selection is not supported by sops-nix. Keep the whole file
    # root-only, and select and validate individual assignments at runtime.
    sops.secrets.rex-env = {
      sopsFile = ../../../../secrets/secrets.env;
      format = "dotenv";
      key = "";
      mode = "0400";
      restartUnits = ["rex-auth.service" "rex-login-server.service"];
    };
    nix.settings.netrc-file = "/run/rex-auth/netrc";
    systemd.services.rex-auth = {
      description = "Prepare validated Rex authentication files";
      before = ["rex-login-server.service"];
      requiredBy = ["rex-login-server.service"];
      restartTriggers = [config.sops.secrets.rex-env.sopsFile renderer];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "rex-auth";
        RuntimeDirectoryMode = "0711";
        RuntimeDirectoryPreserve = true;
        UMask = "0077";
      };
      script = ''
        set -euo pipefail
        ${lib.getExe renderer} accounts ${config.sops.secrets.rex-env.path} /run/rex-auth/accounts.json
        ${lib.getExe renderer} netrc ${config.sops.secrets.rex-env.path} /run/rex-auth/netrc
        chown curtbushko /run/rex-auth/netrc
      '';
    };

    services.tailscale.enable = true;
    services.rex.loginServer = {
      enable = true;
      tailscaleServe.enable = true;
      extraListen = ["${cfg.lanAddress}:7297"];
      allowAnonymous = true;
      accountsFile = "/run/rex-auth/accounts.json";
    };

    # Gamingrig's general firewall is disabled. Protect Rex independently,
    # without flushing Docker's rules or changing access to other services.
    environment.etc."rex/firewall.nft".text = ''
      destroy table inet rex
      table inet rex {
        chain input {
          type filter hook input priority -10; policy accept;
          iifname "lo" tcp dport 7297 accept
          iifname "eno1" ip saddr 192.168.2.0/24 tcp dport 7297 accept
          tcp dport 7297 drop
        }
      }
    '';
    systemd.services.rex-firewall = {
      description = "Restrict anonymous Rex access to the trusted LAN";
      before = ["rex-login-server.service"];
      requiredBy = ["rex-login-server.service"];
      restartTriggers = [config.environment.etc."rex/firewall.nft".source];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.nftables}/bin/nft -f /etc/rex/firewall.nft";
        ExecReload = "${pkgs.nftables}/bin/nft -f /etc/rex/firewall.nft";
        # Keep the rule on stop, including failed activation and shutdown.
        # The next start replaces only this table atomically.
      };
    };
    systemd.services.rex-login-server = {
      requires = ["rex-firewall.service" "rex-auth.service"];
      after = ["rex-firewall.service" "rex-auth.service"];
    };
  };
}
