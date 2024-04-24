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
  git-migrate-to-new-branch = pkgs.writeShellScriptBin "git-migrate-to-new-branch" ''
#!/bin/bash

function confirm() {
	# call with a prompt string or use a default
	read -r -p "${1:-Continue? [y/N]} " RESPONSE
	case "$RESPONSE" in
	[yY][eE][sS] | [yY])
		echo "Continuing... "
		;;
	*)
		echo "Exiting..."
		exit 0
		;;
	esac
}

if test -z "$1"; then

	echo ' This script helps you migrate changes from one branch to another.
    Steps:
    1) Make sure all of your local branches are up to date with origin
    2) Make sure your new branch is created off of the correct parent branch
    3) Git checkout the branch that containers your changes
    4) run this script as ${0} <PARENT_BRANCH> <NEW_BRANCH>

    For example
        $0 main new_feature_2

    '

	echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Error: missing parent branch"
	exit 1
fi

if test -z "$2"; then
	echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Error: missing new branch"
	exit 1
fi

PARENT_BRANCH=$1
NEW_BRANCH=$2
OLD_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CHANGED_FILES="${TMPDIR}/changed_files"

confirm "Migrating changes from '${OLD_BRANCH}' to '${NEW_BRANCH}'. Continue?"
git diff --name-only "${PARENT_BRANCH}" >"${CHANGED_FILES}"

echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Changed files:"
echo "----------------------------------------------"
cat "${CHANGED_FILES}"
echo "----------------------------------------------"

confirm "Migrate files to '${NEW_BRANCH}?'"
echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Checking out new branch '${NEW_BRANCH}':"
git checkout ${NEW_BRANCH}

while read FILE; do
	echo "Checking out ${FILE}"
	git checkout ${OLD_BRANCH} -- ${FILE}
done <${CHANGED_FILES}
'';
in {
  home.packages =
  [
    git-migrate-to-new-branch
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
