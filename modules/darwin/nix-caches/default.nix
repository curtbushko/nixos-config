{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ns.nixCaches;
  caches = import ../../shared/nix-caches.nix;
in {
  options.ns.nixCaches.enable =
    lib.mkEnableOption "upstream binary caches for Determinate Nix"
    // {
      default = !config.nix.enable;
    };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.nix.enable;
        message = "ns.nixCaches requires an externally managed Nix installation.";
      }
    ];

    # Extend Determinate's configuration without replacing installer/user settings.
    environment.etc."nix/nix.repo-caches.conf".text = ''
      extra-substituters = ${lib.concatStringsSep " " caches.substituters}
      extra-trusted-public-keys = ${lib.concatStringsSep " " caches.trusted-public-keys}
    '';

    system.activationScripts.postActivation.text = ''
      PATH=${pkgs.gnugrep}/bin:$PATH \
        ${pkgs.bash}/bin/bash ${../../home/scripts/nix-cache-include} /etc/nix/nix.custom.conf
    '';
  };
}
