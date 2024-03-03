NIXOS_CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
UNAME := $(shell uname | tr '[:upper:]' '[:lower:]')
NIXMACHINE := $(shell hostname -s | tr '[:upper:]' '[:lower:]')
NIXUSER ?= curtbushko
DATELOG := "[$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')]"

vars:
	@echo "UNAME: $(UNAME)"
	@echo "NIXMACHINE: $(NIXMACHINE)"

# Setup nix
setup:
ifeq ($(UNAME), darwin)
	@echo "$(DATELOG) Installing Determinate Nix Installer..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
endif

switch:
	@echo "$(DATELOG) Building nix config"
ifeq ($(UNAME), darwin)
	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${NIXMACHINE}.system" --show-trace
	#nix build ".#darwinConfigurations.${NIXMACHINE}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXMACHINE}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake ".#${NIXHOSTNAME}"
endif

# Update all your packages
update:
	nix --extra-experimental-features 'nix-command flakes' flake update

# Use this when you start getting weird 'file not found' errors from nix-store
repair:
	sudo nix-store --repair --verify --check-contents

# Add the channels before building Nixos
channels:
	sudo nix-channel --add https://nixos.org/channels/nixos-unstable
	sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	sudo nix-channel --update

# With so many switches, things can get full
clean:
	sudo nix-collect-garbage --delete-older-than 5d

format:
	@echo "$(DATELOG) Formatting nix files"
	alejandra --quiet .
