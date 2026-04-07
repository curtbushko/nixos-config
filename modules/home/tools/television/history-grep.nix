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
      pkgs.coreutils # provides tac
      pkgs.gnused # provides sed
      pkgs.gawk # provides awk
    ];

    xdg.configFile."television/cable/history-grep.toml".text = ''
      [metadata]
      name = "history-grep"
      description = "Search and select from zsh history (like hg alias)"
      requirements = ["zsh"]

      [source]
      command = "${pkgs.coreutils}/bin/tac ~/.config/zsh/.zsh_history | ${pkgs.gnused}/bin/sed 's/^: [0-9]*:[0-9]*;//; s/^[[:space:]]*//; s/[[:space:]]*$//' | ${pkgs.gawk}/bin/awk 'NF && !seen[$0]++'"
      display = "{}"
      output = "{}"
    '';

    programs.zsh.shellAliases = {
      hg = "print -z -- $(tv history-grep)";
    };
  };
}
