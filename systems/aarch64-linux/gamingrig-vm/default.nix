{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/base
  ];

  # VM-specific settings
  curtbushko = {
    hardware.audio.enable = true;
    services.wm.enable = true;
  };

  # Use GRUB for VM boot (works better with QEMU/UTM)
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "gamingrig-vm";
  networking.networkmanager.enable = true;

  # DNS resolution
  services.resolved.enable = true;

  # Clear out journalctl logs
  services.journald.extraConfig = "MaxRetentionSec=14day";

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  };

  security.rtkit.enable = true;

  # List packages installed in system profile
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

    # Window managers (choose lighter options for VM)
    sway
    swaybg
    swayidle
  ];

  # Needed to run things like stylua in neovim on nixos
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stylua
    stdenv.cc.cc.lib
  ];

  programs.mtr.enable = true;
  programs.ssh.startAgent = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Enable tailscale
  services.tailscale.enable = true;

  # Firewall
  networking.firewall.enable = false;

  # Hint apps to use wayland
  environment.variables.NIXOS_OZONE_WL = "1";

  # Enable OpenGL for VM (virtio-gpu)
  hardware.graphics = {
    enable = true;
  };

  # Docker/virtualization support
  virtualisation = {
    docker.enable = true;
  };

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  # QEMU guest agent for better VM integration
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Do not change
  system.stateVersion = "24.05";
}
