{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.services.k8s.agent;
in
{
  options.curtbushko.services.k8s.agent = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS k8s agent 
      '';
    };
  };

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  config = mkIf cfg.enable {
    sops.secrets.token = {
      sopsFile = ../../../../../secrets/k3s.yaml;
    };
    sops.age.keyFile = "/home/curtbushko/.config/sops/age/keys.txt";

    services.k3s = {
      enable = true;
      role = "agent";
      serverAddr = "https://node00:6443";
      token = config.sops.secrets.token.path;
      clusterInit = true;
    };
  };
}
