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
      pkgs.git
    ];
    xdg.configFile."television/cable/git-reflog.toml".text = ''
      [metadata]
      name = "git-reflog"
      description = "A channel to select from git reflog entries"
      requirements = ["git"]

      [source]
      command = "${pkgs.git}/bin/git reflog --decorate --color=always"
      output = "{0|strip_ansi}"
      ansi = true

      [preview]
      command = "${pkgs.git}/bin/git show -p --stat --pretty=fuller --color=always '{0|strip_ansi}'"
    '';
  };
}
