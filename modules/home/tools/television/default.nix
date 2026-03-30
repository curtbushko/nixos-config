{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  imports = [
    ./config.nix
    ./dirs.nix
    ./files.nix
    ./git-branch.nix
    ./git-diff.nix
    ./git-log.nix
    ./git-reflog.nix
    ./git-repos.nix
    ./k8s-deployments.nix
    ./k8s-pods.nix
    ./k8s-services.nix
    ./man-pages.nix
    ./history-grep.nix
  ];

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.television
    ];

    programs.zsh.initContent = ''
      # tv wrapper function for cd behavior
      function tv() {
        case "$1" in
          git-repos)
            local result=$(command tv git-repos)
            [[ -n "$result" ]] && print -z -- "cd ~/workspace/$result"
            ;;
          dirs)
            local result=$(command tv dirs)
            [[ -n "$result" ]] && print -z -- "cd $result"
            ;;
          *)
            command tv "$@"
            ;;
        esac
      }
    '';

    programs.zsh.shellAliases = {
      tvg = "tv git-repos";
      tvd = "tv dirs";
    };
  };
}
