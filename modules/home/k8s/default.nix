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
      pkgs.krew
    ];

    # Add krew bin directory to PATH
    programs.zsh.initContent = ''
      export PATH=''$PATH:''$HOME/.krew/bin
    '';

    # Install krew plugins
    home.activation.installKrewPlugins = config.lib.dag.entryAfter ["writeBoundary"] ''
      export PATH="${pkgs.kubectl}/bin:${pkgs.krew}/bin:${pkgs.git}/bin:''$PATH"
      # Use system SSH to support macOS-specific options like UseKeychain
      export GIT_SSH_COMMAND="/usr/bin/ssh"

      # Install ctx plugin (kubectx)
      if ! ${pkgs.krew}/bin/krew list 2>/dev/null | grep -q "^ctx$"; then
        ''$DRY_RUN_CMD ${pkgs.krew}/bin/krew install ctx
      fi

      # Install ns plugin
      if ! ${pkgs.krew}/bin/krew list 2>/dev/null | grep -q "^ns$"; then
        ''$DRY_RUN_CMD ${pkgs.krew}/bin/krew install ns
      fi
    '';
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
