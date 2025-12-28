{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../../modules/nixos/base
  ];

  # StevenBlack/hosts blocklist configuration
  networking.stevenBlackHosts = {
    enable = true;
    blockPorn = true;
    blockGambling = true;
    blockFakenews = true;
    blockSocial = false;
  };

  curtbushko = {
    hardware.audio.enable = true;
    hardware.cpu.enable = true;
    services.wm.enable = true;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "steamdeck";
  networking.networkmanager.enable = true;

  # Work around NetworkManager getting stuck waiting on tailscale0
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = ["" "${pkgs.networkmanager}/bin/nm-online -q"];
    };
  };

  # turn this on so that tailscale works with local addresses also
  # use avahi for mDNS
  services.resolved = {
    enable = true;
    extraConfig = ''
      MulticastDNS=off
    '';
  };
  services.avahi.enable = true;

  # Allow core dumps
  systemd.coredump.enable = true;

  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableSystemSlice = true;
    enableRootSlice = true;
  };

  # clear out journalctl logs
  services.journald.extraConfig = "MaxRetentionSec=14day";

  # Setup auto suspend for portable device
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=yes
  '';

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  };

  security.rtkit.enable = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
        JustWorksRepairing = "always";
        Privacy = "device";
        Enable = "Source,Sink,Media,Socket";
        AutoEnable = true;
        ControllerMode = "dual";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
  services.blueman.enable = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    alsa-oss
    cachix
    cmake
    dconf
    git
    gnumake
    gcc
    gdb
    inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    killall
    pciutils
    lm_sensors
    rxvt-unicode-unwrapped
    vim
    nix-index
    wget
    xclip
    (
      waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
      })
    )
    wayland
    xwayland
    libnotify
    tailscale
    neofetch

    hyprland
    niri
    sway
    swaybg
    swayidle

    # Gaming
    steam-run
    vulkan-tools
    lutris
    protonup-qt
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  programs.ssh.startAgent = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Enable tailscale
  services.tailscale.enable = true;
  systemd.services.tailscaled.after = ["network-online.target" "systemd-resolved.service" "systemd-avahi.service"];
  systemd.services.tailscaled.wants = ["network-online.target" "systemd-resolved.service" "systemd-avahi.service"];

  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # If your cursor becomes invisible
  environment.variables.WLR_NO_HARDWARE_CURSORS = "1";
  # Hint electron apps to use wayland
  environment.variables.NIXOS_OZONE_WL = "1";

  # Might help with making fonts clearer
  environment.variables.FREETYPE_PROPERTIES = "truetype:interpreter-version=35";

  # Enable OpenGL - Steam Deck uses AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  security.pam.services.swaylock = {
    text = ''      ;
      auth include login
    '';
  };

  # Do not change - ever
  system.stateVersion = "24.11";
}
