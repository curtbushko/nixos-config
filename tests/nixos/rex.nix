# nix eval --impure --file tests/nixos/rex.nix
let
  flake = builtins.getFlake (toString ../..);
  system = flake.inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs.inputs = flake.inputs;
    modules = [
      ../../modules/nixos/services/rex/default.nix
      {
        ns.services.rex.enable = true;
        users.users.curtbushko = {
          isNormalUser = true;
        };
        system.stateVersion = "24.11";
        boot.isContainer = true;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
        };
      }
    ];
  };
  inherit (system) config;
  login = config.services.rex.loginServer;
  rules = config.environment.etc."rex/firewall.nft".text;
  prepare = config.systemd.services.rex-auth;
  contains = needle: text: builtins.replaceStrings [needle] [""] text != text;
in
  assert login.enable;
  assert !config.services.rex.enable;
  assert login.tailscaleServe.enable;
  assert login.extraListen == ["192.168.2.55:7297"];
  assert login.allowAnonymous;
  assert login.accounts == {};
  assert login.defaults == {};
  assert login.accountsFile == "/run/rex-auth/accounts.json";
  assert config.sops.secrets.rex-env.key == "";
  assert config.sops.secrets.rex-env.format == "dotenv";
  assert config.sops.secrets.rex-env.mode == "0400";
  assert config.nix.settings.netrc-file == "/run/rex-auth/netrc";
  assert prepare.serviceConfig.UMask == "0077";
  assert builtins.elem "rex-auth.service" config.systemd.services.rex-login-server.requires;
  assert !(builtins.hasAttr "rex-accounts" config.sops.templates);
  assert !(builtins.hasAttr "rex/accounts.jsonc" config.environment.etc);
  assert config.services.tailscale.enable;
  assert builtins.elem "rex-firewall.service" config.systemd.services.rex-login-server.requires;
  assert !config.networking.nftables.enable;
  assert contains "destroy table inet rex" rules;
  assert contains ''iifname "eno1" ip saddr 192.168.2.0/24 tcp dport 7297 accept'' rules;
  assert contains "tcp dport 7297 drop" rules;
  assert builtins.all (a: a.assertion) config.assertions; true
