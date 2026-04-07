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
      pkgs.coreutils # provides ls
    ];

    xdg.configFile."television/cable/dirs.toml".text = ''
      [metadata]
      name = "dirs"
      description = "A channel to select from directories"
      requirements = ["fd"]

      [source]
      command = ["${pkgs.fd}/bin/fd -t d . ~", "${pkgs.fd}/bin/fd -t d --hidden . ~"]

      [preview]
      command = "${pkgs.coreutils}/bin/ls -la --color=always '{}'"
    '';
  };
}
