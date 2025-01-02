{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./hosts.nix
    ../../../modules/nixos/base
  ];

  curtbushko = {
    hardware.audio.enable = false;
    services.k8s.server.enable = true;
    services.llm.enable = false;
    services.minecraft.enable = false;
    services.wm.enable = false;
  };

  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "node00"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.interfaces.eno1.wakeOnLan.enable = true;

  # turn this on so that tailscale works with local addresses also
  services.resolved.enable = true;

  # Allow core dumps
  systemd.coredump.enable = true;

  # clear out journalctl logs
  services.journald.extraConfig = "MaxRetentionSec=14day";

  # Setup auto suspend
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.curtbushko = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    wget
    lm_sensors
    cachix
    cmake
    dconf
    git
    gnumake
    gcc
    gdb
    killall
    pciutils
    vim
    nix-index
    wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  programs.ssh.startAgent = true;
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Docker
  #virtualisation = {
  #  libvirtd.enable = true;
  #  docker.enable = true;
  #};

  # Do not change - ever
  system.stateVersion = "24.11"; # Did you read the comment?
}
