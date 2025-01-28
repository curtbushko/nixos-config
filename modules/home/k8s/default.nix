{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.k8s;
in {
  options.curtbushko.k8s = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable k8s tools and context
      '';
    };
  };

  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.kind
      pkgs.kubebuilder
      pkgs.kubectl
      pkgs.kubectx
    ];
    # extract kubecontext
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      secrets.kubecontext = {
        path = "${config.home.homeDirectory}/.kube/config";
        sopsFile = ../../../secrets/kubecontext.yaml;
        format = "yaml";
        key = "";
        mode = "0600";
      };
    };
  };
}
