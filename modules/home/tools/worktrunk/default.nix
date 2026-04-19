{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;

  wt-checkout = pkgs.writeScriptBin "wt-checkout" ''
    #!/usr/bin/env bash
    set -e

    # If arguments provided, pass directly to wt switch
    if [ $# -gt 0 ]; then
      exec wt switch "$@"
    fi

    # No arguments - show interactive picker for remote branches
    # Redirect stdin to /dev/tty so fzf can work through aliases
    #exec </dev/tty

    BRANCH=$(git branch -r | grep -v HEAD | sed 's/^[* ]*//' | ${pkgs.fzf}/bin/fzf --prompt="Select remote branch: ")

    if [ -n "$BRANCH" ]; then
      # Remove 'origin/' prefix if present
      BRANCH_NAME=$(echo "$BRANCH" | sed 's|^origin/||')
      wt switch "$BRANCH_NAME"
    fi
  '';

  wt-clone = pkgs.writeScriptBin "wt-clone" ''
    #!/usr/bin/env bash
    set -e

    URL="$1"
    if [ -z "$URL" ]; then
      echo "Usage: wt clone <git-url>"
      exit 1
    fi

    # Parse URL to extract HOST, ORG, and REPO
    if [[ "$URL" =~ ^(https?://|git@)([^/:]+)[/:]([^/]+)/(.+)(\.git)?$ ]]; then
      HOST="''${BASH_REMATCH[2]}"
      ORG="''${BASH_REMATCH[3]}"
      REPO="''${BASH_REMATCH[4]}"
      REPO="''${REPO%.git}"
    else
      echo "Error: Could not parse git URL: $URL"
      exit 1
    fi

    TARGET_DIR="$HOME/workspace/$HOST/$ORG/$REPO"

    if [ -d "$TARGET_DIR" ]; then
      echo "Error: Directory already exists: $TARGET_DIR"
      exit 1
    fi

    echo "Cloning $URL to $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"

    git clone --bare "$URL" .bare
    echo "gitdir: ./.bare" > .git
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch origin

    # Set remote HEAD to track default branch
    git remote set-head origin -a

    # Get default branch and create initial worktree
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [ -z "$DEFAULT_BRANCH" ]; then
      # Fallback: try to detect from remote
      DEFAULT_BRANCH=$(git ls-remote --symref origin HEAD | grep '^ref:' | sed 's@^ref: refs/heads/@@;s@[[:space:]].*@@')
    fi

    git worktree add "$DEFAULT_BRANCH"

    echo ""
    echo "Repository cloned successfully!"
    echo "Location: $TARGET_DIR/$DEFAULT_BRANCH"
  '';
in {
  config = mkIf cfg.enable {
    home.packages = [wt-checkout wt-clone];
    programs.worktrunk = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    # Worktrunk user configuration
    xdg.configFile."worktrunk/config.toml".source = ./config.toml;
  };
}
