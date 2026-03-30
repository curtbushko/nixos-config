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
      pkgs.git
    ];
    xdg.configFile."television/cable/git-repos.toml".text = ''
      [metadata]
      name = "git-repos"
      requirements = ["fd", "git"]
      description = """
      A channel to select from git repositories in ~/workspace.
      """

      [source]
      command = "cd ~/workspace && fd -g .git -HL -t d -d 10 --prune . --exec dirname '{}' | sed 's|^\\./||'"
      display = "{}"

      [preview]
      command = "cd ~/workspace/'{}'; git log -n 200 --pretty=medium --all --graph --color"

      [keybindings]
      ctrl-e = "actions:open-in-nvim"

      [actions.open-in-nvim]
      description = "open in nvim"
      command = "nvim ~/workspace/{}"
      mode = "execute"
    '';
  };
}
