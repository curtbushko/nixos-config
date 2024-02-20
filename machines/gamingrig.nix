# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware/gamingrig.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "gamingrig"; # Define your hostname.
  # Pick only one of the below networking options.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Americas/Toronto";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
	font = "Lat2-Terminus12";
  };


  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Font setup
  fonts = {
	fontDir.enable = true;
	fonts = with pkgs; [
		fira-code
		font-awesome_5
		jetbrains-mono
		nerdfonts
		noto-fonts
		noto-fonts-extra
		noto-fonts-emoji
		powerline-fonts
	];
	fontconfig = {
		enable = true; 
		antialias = true;
		
		defaultFonts = {
			monospace = [ "Jetbrains Mono" "Noto Mono" ];
			serif = [ "Noto Serif" ];
			sansSerif = [ "Noto Sans" ];
			emoji = [ "Noto Color Emoji" ];
		};
	};
  };  

  # Nixpkgs Setup
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     cachix
     git
     gnumake
     killall
     pciutils
     rxvt_unicode
     vim
     wget
     xclip
   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
  };

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

  # Enable the X11 windowing system.
  services.xserver = {
	enable = false;
	#layout = "us";
     	# dpi = 220; # Mitchell had this... do I need it for my widescreen monitor?

	#desktopManager = {
	#	xterm.enable = false;
	#	wallpaper.mode = "fill";
	#};

	#displayManager = {
	#	defaultSession = "none+i3";
	#	lightdm.enable = true;
	#};

	#windowManager = {
	#	i3.enable = true;
	#};
  };


  # Enable OpenGL
  hardware.opengl = {
	enable = true; 
	driSupport = true;
	driSupport32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
	# Modesetting is required.
	modesetting.enable = true;

	# Nvidia power management. Experimental, and can cause sleep/suspend to fail.
	powerManagement.enable = false;
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
	package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Do not change - ever
  system.stateVersion = "23.11";

}

