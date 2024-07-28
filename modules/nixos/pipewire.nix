{...}: {
  # Pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  hardware.pulseaudio.support32Bit = true;

  # No beeping
  boot.blacklistedKernelModules = [
    "pcspkr"
    "snd_pcsp"
  ];

  services.pipewire.extraConfig.pipewire = {
    "99-silent-bell" = {
      "context.properties" = {
        "module.x11.bell" = false;
      };
    };
  };
}
