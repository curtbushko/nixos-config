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
    xdg.configFile."television/cable/git-diff.toml".text = ''
      [metadata]
      name = "git-diff"
      description = "A channel to select files from git diff commands"
      requirements = ["git"]

      [source]
      command = "${pkgs.git}/bin/git diff --name-only HEAD"

      [preview]
      command = "${pkgs.git}/bin/git diff HEAD --color=always -- '{}'"
    '';
  };
}
