{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.hardware.cpu;
in {
  config = mkIf cfg.enable {

    programs.coolercontrol = {
      enable = true;
      nvidiaSupport = true;
    };

    # Fix XAUTHORITY access for nvidia-settings
    systemd.services.coolercontrold = {
      environment = {
        DISPLAY = ":0";
        XAUTHORITY = "/home/curtbushko/.Xauthority";
      };
      serviceConfig = {
        # Wait for display server to be ready
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      };
    };
  };
}
