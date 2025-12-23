{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    # Import VM-specific hardware configuration
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
    services.llm.enable = true;
    services.minecraft.enable = false;
    services.vr.enable = false; # Disabled for VM
    services.wm.enable = true; # qt and wayland
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VM-specific configuration
  virtualisation.vmVariant = {
    # Enable virtiofs for shared folders
    virtualisation.sharedDirectories = {
      home = {
        source = "$HOME";
        target = "/mnt/host-home";
      };
    };

    # Allocate more resources for the VM
    virtualisation.cores = 4;
    virtualisation.memorySize = 8192; # 8GB RAM
    virtualisation.diskSize = 50000; # 50GB disk

    # Use virtio for better performance
    virtualisation.qemu.options = [
      "-vga virtio"
      "-display gtk,gl=on"
    ];
  };

  networking.hostName = "gamingrig-vm"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

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

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  };

  security.rtkit.enable = true;

  # Bluetooth disabled for VM
  hardware.bluetooth.enable = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
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
    libnotify # notifications too.
    tailscale
    neofetch

    hyprland
    niri
    sway
    swaybg
    swayidle

    # Gaming packages (some may work in VM)
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

    xorg.libXcomposite
    xorg.libXtst
    xorg.libXrandr
    xorg.libXext
    xorg.libX11
    xorg.libXfixes
    libGL
    libva

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

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Enable tailscale
  services.tailscale.enable = true;
  # Try and slow down startup of tailscaled after waking up
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

  # Enable OpenGL for VM (using virtio/llvmpipe)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Docker and virtualization
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
      };
    };
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
