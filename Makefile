NIXOS_CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
UNAME := $(shell uname | tr '[:upper:]' '[:lower:]')
NIXMACHINE := $(shell hostname -s | tr '[:upper:]' '[:lower:]')
NIXUSER ?= curtbushko

vars:
	@echo "UNAME: $(UNAME)"
	@echo "NIXMACHINE: $(NIXMACHINE)"

# Setup nix
setup:
	@echo "Installing Determinate Nix Installer..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

switch:
ifeq ($(UNAME), darwin)
	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${NIXMACHINE}.system" --show-trace
	#nix build ".#darwinConfigurations.${NIXMACHINE}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXMACHINE}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake ".#${NIXHOSTNAME}"
endif

# Update all your packages
update:
	nix flake update

# Use this when you start getting weird 'file not found' errors from nix-store
repair:
	sudo nix-store --repair --verify --check-contents
