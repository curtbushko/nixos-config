{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  config = mkIf cfg.enable {
    xdg.configFile."television/cable/history-grep.toml".text = ''
      [metadata]
      name = "history-grep"
      description = "Search and select from zsh history (like hg alias)"
      requirements = ["zsh"]

      [source]
      command = "tac ~/.config/zsh/.zsh_history | sed 's/^: [0-9]*:[0-9]*;//; s/^[[:space:]]*//; s/[[:space:]]*$//' | awk 'NF && !seen[$0]++'"
      display = "{}"
      output = "{}"
    '';

    programs.zsh.shellAliases = {
      hg = "print -z -- $(tv history-grep)";
    };
  };
}
