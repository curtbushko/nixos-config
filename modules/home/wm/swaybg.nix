{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;

  # Wallpaper SHA256 hashes
  wallpaperHashes = {
    "firewatch-green.jpg" = "sha256-ILiIAcw9JMHsRNT63TnR3kn1O4IwEliJtb2FwdIQUEM=";
    "cyberpunk-tokyo.png" = lib.fakeHash;
    "cyberpunk_2077_phantom_liberty_katana.jpg" = "sha256-j4lo10bA9IT/qVE6LrFXbT6Gc85LYcS9xvMeeoEjq3U=";
    "green-pasture.jpg" = lib.fakeHash;
    "cyberpunk-three.png" = lib.fakeHash;
  };

  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/curtbushko/nixos-wallpapers/main/3440x1440/${config.curtbushko.theme.wallpaper}";
    sha256 = wallpaperHashes.${config.curtbushko.theme.wallpaper} or lib.fakeHash;
  };
in {
  config = mkIf cfg.enable {
    systemd.user.services.swaybg = {
      Unit = {
        PartOf = ["niri.service"];
        After = ["niri.service"];
        Requires = ["niri.service"];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Install = {
        WantedBy = ["niri.service"];
      };
      Service = {
        Restart = "on-failure";
        RestartSec = 3;
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs.swaybg)
          "--mode"
          "fill"
          "--image"
          "${wallpaper}"
        ];
      };
    };
  };
}
