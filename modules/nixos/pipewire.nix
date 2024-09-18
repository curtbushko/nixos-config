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

  services.pipewire.wireplumber.extraConfig."10-bluez" = {
    "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.enable-hw-volume" = true;
      "bluez5.roles" = [
        "hsp_hs"
        "hsp_ag"
        "hfp_hf"
        "hfp_ag"
      ];
    };
  };

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
