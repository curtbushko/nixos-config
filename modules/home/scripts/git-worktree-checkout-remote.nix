{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  git-worktree-checkout-remote = pkgs.writeShellScriptBin "git-worktree-checkout-remote" ''
#!/bin/bash
# 	OWNER=$(gh repo view --json owner --jq .owner.login)
# 	echo "Owner: $OWNER"
# 	REPO=$(gh repo view --json name --jq .name)
# 	echo "Repo: $REPO"
_git-worktree-checkout() {
	BRANCH=$(
		git branch -r --sort=-committerdate |
			fzf --ansi --border-label="| Branches |" --height=90% --border=rounded \
				--margin=2,2,2,2 --prompt "checkout worktree: " --preview-window=top:40% \
				--preview='git log --oneline -n10 {1}' \
				--bind "j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up"
	)

	if [ "${BRANCH}" != "" ]; then
		BRANCH=$(echo ${BRANCH} | tr -d '[:space:]' | sed 's^origin\/^^g')
		echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Branch: ${BRANCH}"
		git worktree add "${BRANCH}" -B "${BRANCH}" "origin/${BRANCH}"
		echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Worktrees:"
		git worktree list
	fi

}

_git-worktree-checkout "$@"
'';
in {
  home.packages =
  [
    git-worktree-checkout-remote
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
