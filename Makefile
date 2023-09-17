
NIXOS_CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
NIX_OS := $(shell uname | tr '[:upper:]' '[:lower:]')
NIX_HOSTNAME := $(shell hostname | tr '[:upper:]' '[:lower:]')
NIX_USER := $(shell id -un | tr '[:upper:]' '[:lower:]')
UNAME := $(shell uname)

vars:
	@echo "NIX_OS: $(NIX_OS)"
	@echo "NIX_HOSTNAME: $(NIX_HOSTNAME)"
	@echo "NIX_USER: $(NIX_USER)"

# Setup nix 
setup:
	@echo "Installing Determinate Nix Installer..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

link:
	@echo "Linking nix configuration"
	rm -rf $(HOME_MANAGER)
	ln -s "$(DOTFILE_DIR)" "$(HOME_MANAGER)"

switch:
ifeq ($(UNAME), Darwin)
	nix build ".#darwinConfigurations.${NIX_HOSTNAME}.system"
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
