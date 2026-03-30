{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.fd
    ];

    xdg.configFile."television/cable/dirs.toml".text = ''
      [metadata]
      name = "dirs"
      description = "A channel to select from directories"
      requirements = ["fd"]

      [source]
      command = ["fd -t d . ~", "fd -t d --hidden . ~"]

      [preview]
      command = "ls -la --color=always '{}'"
    '';
  };
}
