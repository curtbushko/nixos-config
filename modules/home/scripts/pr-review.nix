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
  pr-review = pkgs.writeShellScriptBin "pr-review" ''
#!/bin/bash
# 	OWNER=$(gh repo view --json owner --jq .owner.login)
# 	echo "Owner: $OWNER"
# 	REPO=$(gh repo view --json name --jq .name)
# 	echo "Repo: $REPO"
_pr-review() {
	PR=$(
		GH_FORCE_TTY=100% gh pr list -s open -S user-review-requested:@me |
			fzf --ansi --preview 'GH_FORCE_TTY=100% gh pr view {1}' \
				--bind "j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort" \
				--preview-window=top:80% --header-lines 3 |
			awk '{print $1}'
	)

	if [ -z "${PR}" ]; then
		exit 0
	fi

	PR=${PR:1}
	echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] PR: ${PR}"
	BRANCH=$(gh pr view ${PR} --json headRefName --jq .headRefName)
	echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Branch: ${BRANCH}"

	mkdir -p reviews
	git worktree add "reviews/${BRANCH}" -b "${BRANCH}" "origin/${BRANCH}"

	echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Worktrees:"
	git worktree list
}

_pr-review "$@"
'';
in {
  home.packages =
  [
    pr-review
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
