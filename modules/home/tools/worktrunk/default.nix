{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;

  wt-clone = pkgs.writeScriptBin "wt-clone" ''
    #!/usr/bin/env bash
    set -e

    # Handle --help flag
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
      echo "wt clone - Clone a repository into a bare git worktree setup"
      echo ""
      echo "Usage: wt clone <git-url>"
      echo ""
      echo "Clones a git repository using bare clone + worktree pattern:"
      echo "  - Creates directory at ~/workspace/<host>/<org>/<repo>"
      echo "  - Sets up .bare directory with git data"
      echo "  - Creates initial worktree for default branch"
      echo "  - Changes to the worktree directory after clone"
      echo ""
      echo "Examples:"
      echo "  wt clone https://github.com/user/repo"
      echo "  wt clone git@github.com:user/repo.git"
      exit 0
    fi

    URL="$1"
    if [ -z "$URL" ]; then
      echo "Usage: wt clone <git-url>"
      echo "Run 'wt clone --help' for more information."
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

    # Create worktree with local branch tracking remote
    git worktree add -B "$DEFAULT_BRANCH" "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"

    # Ensure tracking is set up properly
    cd "$DEFAULT_BRANCH"
    git branch --set-upstream-to="origin/$DEFAULT_BRANCH" "$DEFAULT_BRANCH"
    cd ..

    FINAL_DIR="$TARGET_DIR/$DEFAULT_BRANCH"

    echo ""
    echo "Repository cloned successfully!"
    echo "Location: $FINAL_DIR"

    # Write to worktrunk's directive file so shell wrapper cds after script exits
    if [ -n "$WORKTRUNK_DIRECTIVE_CD_FILE" ]; then
      echo "$FINAL_DIR" > "$WORKTRUNK_DIRECTIVE_CD_FILE"
    fi
  '';
in {
  config = mkIf cfg.enable {
    home.packages = [wt-clone];
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
