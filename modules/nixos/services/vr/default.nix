{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.services.vr;
in {
  options.ns.services.vr = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable VR
      '';
    };
  };

  config = mkIf cfg.enable {
    # should allow scripts that use /bin/bash to work
    services.envfs.enable = true;

    # Enable udev rules for slimevr devices
    services.udev.packages = [pkgs.slimevr];

    environment.systemPackages = with pkgs; [
      android-tools
      libcap
      libdrm
      openvr
      openssl
      udev
      gobject-introspection
      mesa
      monado-vulkan-layers
      usbutils
      xdg-utils
      xdg-user-dirs
      # used by wabbajack installer (Skyrim VR)
      protontricks
      flatpak
      winetricks
      wineWow64Packages.stable
      wineWow64Packages.waylandFull
      freetype
      steamtinkerlaunch
      cemu
      python3
      python3Packages.pycairo
      python3Packages.pygobject3
      slimevr
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      extraPackages = with pkgs; [
        monado-vulkan-layers
      ];
    };
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };
    hardware.steam-hardware.enable = true;

    # Configure monado
    services.monado = {
      enable = true;
      highPriority = true;
      # defaultRuntime = true;
    };
    hardware.graphics.extraPackages = [pkgs.monado-vulkan-layers pkgs.gamemode];

    # SteamVR is installed into the user's Steam library, which is unavailable
    # inside Nix's build sandbox and cannot be a declarative security-wrapper source.
    # Steam/Monado manage the user-installed launchers directly.

    # Configure WiVRn
    services.wivrn = {
      enable = true;
      openFirewall = true;
      autoStart = true;
    };

    services.avahi.enable = true;

    programs.alvr = {
      enable = false; # 2025-09-16 - turning off because nix build is failing
      openFirewall = true;
    };


    # create a wireless access point
    services.create_ap = {
      enable = false;
      settings = {
        INTERNET_IFACE = "eno1";
        WIFI_IFACE = "wlp9s0";
        SSID = "hotspotvr";
        PASSPHRASE = "12345678";
      };
    };

    xdg.mime.enable = true;
  };
}
