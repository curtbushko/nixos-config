# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  networking.hostName = "nixos-vm"; # Define your hostname.
  # Pick only one of the below networking options.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Americas/Toronto";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  };

  # Enable sound with pipewire.
  #sound.enable = true;
  #security.rtkit.enable = true;
  #services.pipewire = {
  #  enable = true;
  #  alsa.enable = true;
  #  alsa.support32Bit = true;
  #  pulse.enable = true;
  #  jack.enable = true;
  #};

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Nixpkgs Setup
  #nixpkgs.config.allowUnfree = true;
  #nixpkgs.config.allowUnsupportedSystem = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    git
    gnumake
    gcc
    killall
    pciutils
    rxvt_unicode
    vim
    wget
    xclip
    waybar
    (
      waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
      })
    )
    dunst # notifications
    libnotify # notifications too.
    swww # wallpapers

    rofi # app launcher
    rofi-wayland
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # If your cursor becomes invisible
  environment.variables.WLR_NO_HARDWARE_CURSORS = "1";
  # Hint electron apps to use wayland
  environment.variables.NIXOS_OZONE_WL = "1";

  # For accessing resources outside of the sandbox
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-wlr];
    config.common.default = "*";
  };

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    #driSupport32Bit = true;
  };

  #hardware.nvidia = {
  # Modesetting is required.
  #modesetting.enable = true;

  # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
  #powerManagement.enable = false;
  # Fine-grained power management. Turns off GPU when not in use.
  # Experimental and only works on modern Nvidia GPUs (Turing or newer).
  #powerManagement.finegrained = false;

  # Use the NVidia open source kernel module (not to be confused with the
  # independent third-party "nouveau" open source driver).
  # Support is limited to the Turing and later architectures. Full list of
  # supported GPUs is at:
  # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
  # Only available from driver 515.43.04+
  # Currently alpha-quality/buggy, so false is currently the recommended setting.
  #open = false;

  # Enable the Nvidia settings menu,
  # accessible via `nvidia-settings`.
  #nvidiaSettings = true;

  # Optionally, you may need to select the approprate driver version for your specifc GPU.
  #package = config.boot.kernelPackages.nvidiaPackages.stable;
  #};

  # Docker
  #virtualisation = {
  #  libvirtd.enable = true;
  #  docker.enable = true;
  #};

  system.stateVersion = "23.11"; # Did you read the comment?
}
