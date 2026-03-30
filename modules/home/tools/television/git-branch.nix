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
    xdg.configFile."television/cable/git-branch.toml".text = ''
      [metadata]
      name = "git-branch"
      description = "A channel to select from git branches"
      requirements = ["git"]

      [source]
      command = "git --no-pager branch --all --format=\"%(refname:short)\""
      output = "{split: :0}"

      [preview]
      command = "git show -p --stat --pretty=fuller --color=always '{0}'"
    '';
  };
}
