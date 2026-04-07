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
      pkgs.coreutils # provides head
    ];
    xdg.configFile."television/cable/git-log.toml".text = ''
      [metadata]
      name = "git-log"
      description = "A channel to select from git log entries"
      requirements = ["git"]

      [source]
      command = "${pkgs.git}/bin/git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --color=always"
      output = "{strip_ansi|split: :1}"
      ansi = true

      [preview]
      command = "${pkgs.git}/bin/git show -p --stat --pretty=fuller --color=always '{strip_ansi|split: :1}' | ${pkgs.coreutils}/bin/head -n 1000"
    '';
  };
}
