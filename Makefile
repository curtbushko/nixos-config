NIXOS_CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
NIX_OS := $(shell uname | tr '[:upper:]' '[:lower:]')
NIX_HOSTNAME := $(shell hostname -s | tr '[:upper:]' '[:lower:]')
UNAME := $(shell uname)

vars:
	@echo "NIX_OS: $(NIX_OS)"
	@echo "NIX_HOSTNAME: $(NIX_HOSTNAME)"

# Setup nix
setup:
	@echo "Installing Determinate Nix Installer..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

switch:
ifeq ($(UNAME), Darwin)

	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${NIX_HOSTNAME}.system" --show-trace
	#nix build ".#darwinConfigurations.${NIX_HOSTNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIX_HOSTNAME}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake ".#${NIXHOSTNAME}"
endif

# Update all your packages
update:
	nix flake update

# Use this when you start getting weird 'file not found' errors from nix-store
repair:
	sudo nix-store --repair --verify --check-contents
