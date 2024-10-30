NIXOS_CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
OS := $(shell uname | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | tr '[:upper:]' '[:lower:]')
HOST := $(shell hostname -s | tr '[:upper:]' '[:lower:]')
NIXUSER ?= curtbushko
DATELOG := "[$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')]"

.PHONY: default
default: switch

.PHONY: setup
setup: ## Setup nix on darwin only.
ifeq ($(OS), darwin)
	@echo "$(DATELOG) Installing Determinate Nix Installer..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
endif

.PHONY: switch
switch: ## Build and switch your nix config.
	@echo "$(DATELOG) Building nix config"
ifeq ($(OS), darwin)
	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${HOST}.system" --show-trace
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${HOST}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_ARCH=1 nixos-rebuild switch --flake ".#${HOST}"
endif

.PHONY: test
test: ## Test your nix config.
	@echo "$(DATELOG) Testing nix config"
ifeq ($(OS), darwin)
	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${HOST}.system" --show-trace
	./result/sw/bin/darwin-rebuild test --flake "$$(pwd)#${HOST}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_ARCH=1 nixos-rebuild test --flake ".#${HOST}"
endif

.PHONY: update
update: ## Update all of your packages
	nix --extra-experimental-features 'nix-command flakes' flake update

.PHONY: update-neovim
update-neovim: ## Update the neovim flake
	nix flake lock --update-input neovim

.PHONY: update-zenbrowser
update-zenbrowser: ## Update the zen browser 
	nix flake lock --update-input zen-browser

.PHONY: repair
repair: ## Use this when you start getting weird 'file not found' errors from nix-store.
	sudo nix-store --repair --verify --check-contents

.PHONY: channels
channels:  ## Add the channels before building Nixos
	sudo nix-channel --add https://nixos.org/channels/nixos-unstable
	sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	sudo nix-channel --update

.PHONY: gc clean
clean: gc
gc: ##  Garbage collect nix files that are older than 5 days.
	@echo "$(DATELOG) Garbage collecting nix files older than 5 days"
	sudo nix-collect-garbage --delete-older-than 5d

.PHONY: fmt
fmt: ## format nix files
	@echo "$(DATELOG) Formatting nix files"
	alejandra --quiet .

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


