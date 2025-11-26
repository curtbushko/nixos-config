{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.hardware.audio;
in {
  config = mkIf cfg.enable {
    # 2024.11.04
    # Bypassing some rkit bugs that are causing audio problems
    # See: https://github.com/heftig/rtkit/issues/32
    security.pam.loginLimits = [
      { domain = "@audio"; item = "rtprio"; type = "-"; value = 95; }
      { domain = "@audio"; item = "nice"; type = "-"; value = -19; }
      { domain = "@audio"; item = "memlock"; type = "-"; value = 4194304; }
    ];

    security.rtkit = {
      enable = true;
      args = [ "--no-canary" ]; # bypass from above
    };
    # Pipewire
    # Explicitly disable PulseAudio when using PipeWire
    services.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # services.pipewire.wireplumber.extraConfig = {
    #   bluetooth = {
    #     "wireplumber.settings" = {
    #       "bluetooth.autoswitch-to-headset-profile" = false;
    #     };
    #
    #     "10-bluez" = {
    #       "monitor.bluez.properties" = {
    #         "bluez5.enable-sbc-xq" = true;
    #         "bluez5.enable-msbc" = true;
    #         "bluez5.enable-hw-volume" = true;
    #         "bluez5.roles" = [
    #           "hsp_hs"
    #           "hsp_ag"
    #           "hfp_hf"
    #           "hfp_ag"
    #         ];
    #       };
    #     };
    #   };
    # };

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
  };
}
