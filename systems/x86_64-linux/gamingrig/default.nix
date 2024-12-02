# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./hosts.nix
    ../../../modules/nixos
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "gamingrig"; # Define your hostname.
  # Pick only one of the below networking options.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.interfaces.eno1.wakeOnLan.enable = true;

  # Work around NetworkManager getting stuck waiting on tailscale0
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = ["" "${pkgs.networkmanager}/bin/nm-online -q"];
    };
  };

  # Allow core dumps
  systemd.coredump.enable = true;

  # Setup settings so that I can access the video card devices to control the monitor
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  # clear out journalctl logs
  services.journald.extraConfig = "MaxRetentionSec=14day";

  # Setup auto suspend of gamingrig
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=yes
  '';

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  };

  security.rtkit.enable = true;

  # Enable bluetoolth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      FastConnectable = true;
      JustWorksRepairing = "always";
      Privacy = "device";
      Enable = "Source,Sink,Media,Socket";
    };
    Policy = {
      AutoEnable = true;
    };
  };
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Nixpkgs Setup
  #nixpkgs.config.allowUnfree = true;
  #nixpkgs.config.allowUnsupportedSystem = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alsa-oss
    cachix
    cmake
    dunst # notifications
    dconf
    git
    gnumake
    gcc
    gdb
    killall
    pciutils
    rxvt-unicode-unwrapped
    ryujinx
    vim
    nix-index
    wget
    xclip
    waybar
    (
      waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
      })
    )
    wayland
    xwayland
    (
      # 2024.07.06 - Use and older version of xwayland because it is
      # having flickering problems when gaming in hyprland.
      xwayland.overrideAttrs (oldAttrs: {
        version = "23.2.7";
      })
    )
    libnotify # notifications too.
    swww # wallpapers
    tailscale
    neofetch

    rofi # app launcher
    rofi-wayland
    hyprland
    sway
    swayidle

    # Gaming
    cudaPackages.cuda_nvcc
    vulkan-tools
    lutris
    protonup-qt
    #sunshine
    inputs.suyu.packages.x86_64-linux.suyu
  ];

  # Needed to run things like stylua in neovim on nixos
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stylua
    stdenv.cc.cc.lib

    # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L72-L79
    xorg.libXcomposite
    xorg.libXtst
    xorg.libXrandr
    xorg.libXext
    xorg.libX11
    xorg.libXfixes
    libGL
    libva

    # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L124-L136
    fontconfig
    freetype
    xorg.libXt
    xorg.libXmu
    libogg
    libvorbis
    SDL
    SDL2_image
    glew110
    libdrm
    libidn
    tbb
    zlib
  ];
  # Saving this as it might be useful
  #environment.variables = {
  #  NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
  #    pkgs.stdenv.cc.cc
  #    pkgs.openssl
  # add here the libraries you want...
  #  ];
  #  NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  # };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  programs.ssh.startAgent = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Enable tailscale
  services.tailscale.enable = true;
  # Try and slow down startup of tailscaled after waking up
  systemd.services.tailscaled.after = ["network-online.target" "systemd-resolved.service"];
  systemd.services.tailscaled.wants = ["network-online.target" "systemd-resolved.service"];

  # If I decide to turn on the firewall
  #networking.firewall.allowedUDPPorts = [ ${services.tailscale.port} ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # If your cursor becomes invisible
  environment.variables.WLR_NO_HARDWARE_CURSORS = "1";
  # Hint electron apps to use wayland
  environment.variables.NIXOS_OZONE_WL = "1";

  # Might help with making fonts clearer
  environment.variables.FREETYPE_PROPERTIES = "truetype:interpreter-version=35";

  # For accessing resources outside of the sandbox
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    config.common.default = "*";
  };

  # Enable OpenGL
  services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [nvidia-vaapi-driver];
  };

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the approprate driver version for your specifc GPU.
    #package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "565.57.01";
      sha256_64bit = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
      sha256_aarch64 = "sha256-aDVc3sNTG4O3y+vKW87mw+i9AqXCY29GVqEIUlsvYfE=";
      openSha256 = "sha256-/tM3n9huz1MTE6KKtTCBglBMBGGL/GOHi5ZSUag4zXA=";
      settingsSha256 = "sha256-H7uEe34LdmUFcMcS6bz7sbpYhg9zPCb/5AmZZFTx1QA=";
      persistencedSha256 = "sha256-hdszsACWNqkCh8G4VBNitDT85gk9gJe1BlQ8LdrYIkg=";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  hardware.steam-hardware.enable = true;

  # Docker
  virtualisation = {
    libvirtd.enable = true;
    docker.enable = true;
  };

  security.pam.services.swaylock = {
    text = ''      ;
      auth include login
    '';
  };

  users = {
    groups = {
      nm-openconnect = {};
      #netdev = {};
    };
    extraGroups = {
      # Fix for D-Bus error on missing group: netdev
      netdev = {name = "netdev";};
    };
    extraUsers = {
      # Fix for D-Bus error on missing user: nm-openconnect
      nm-openconnect = {
        name = "nm-openconnect";
        description = "System user to control OpenConnect in NetworkManager";
        isSystemUser = true;
        group = "nm-openconnect";
        extraGroups = [
          "netdev"
          "networkmanager"
        ];
      };
    };
  };

  # Do not change - ever
  system.stateVersion = "23.11";
}
