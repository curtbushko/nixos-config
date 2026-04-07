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
      pkgs.coreutils # provides dirname
      pkgs.gnused # provides sed
    ];
    xdg.configFile."television/cable/git-repos.toml".text = ''
      [metadata]
      name = "git-repos"
      requirements = ["fd", "git"]
      description = """
      A channel to select from git repositories in ~/workspace.
      """

      [source]
      command = "cd ~/workspace && ${pkgs.fd}/bin/fd -g .git -HL -t d -d 10 --prune . --exec ${pkgs.coreutils}/bin/dirname '{}' | ${pkgs.gnused}/bin/sed 's|^\\./||'"
      display = "{}"

      [preview]
      command = "cd ~/workspace/'{}'; ${pkgs.git}/bin/git log -n 200 --pretty=medium --all --graph --color"

      [keybindings]
      ctrl-e = "actions:open-in-nvim"

      [actions.open-in-nvim]
      description = "open in nvim"
      command = "nvim ~/workspace/{}"
      mode = "execute"
    '';
  };
}
