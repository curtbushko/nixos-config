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
  git-worktree-switch = pkgs.writeShellScriptBin "git-worktree-switch" ''
#!/bin/bash

# Run this with an alias or else the 'cd' will not work.
# Eg: alias gwts=". git-worktree-switch"

_wt-switch() {
	WT=$(
		git worktree list |
			fzf --ansi --border-label="| Worktrees |" --height=90% --border=rounded \
				--margin=2,2,2,2 --prompt "worktree: " --preview-window=top:80% \
				--preview='git log --oneline -n10 {2}' \
				--bind "j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort" |
			awk '{print $1}'

	)
	if [ "${WT}" != "" ]; then
		cd $WT
	fi
}

_wt-switch
'';
in {
  home.packages =
  [
    git-worktree-switch
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
