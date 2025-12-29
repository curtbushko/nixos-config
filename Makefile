NIXOS_CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
OS := $(shell uname | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | tr '[:upper:]' '[:lower:]')
HOST := $(shell hostname -s)
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
	@echo "$(DATELOG) Building nix config for $(HOST)"
ifeq ($(OS), darwin)
	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${HOST}.system" --show-trace
	sudo ./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${HOST}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_ARCH=1 nixos-rebuild switch --flake ".#${HOST}"
endif

.PHONY: relay
relay: ## Build and switch relay's home-manager config using gamingrig as remote builder
	@echo "$(DATELOG) Building home-manager config for relay using gamingrig as remote builder"
	nix run nixpkgs#home-manager -- switch --flake ".#curtbushko@relay" \
		--option builders 'ssh://curtbushko@gamingrig x86_64-linux - 4 - big-parallel,benchmark'

.PHONY: dry-build
dry-build: ## Build and switch your nix config.
	@echo "$(DATELOG) Building dry build of nix config"
ifeq ($(OS), darwin)
	@echo "skip"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_ARCH=1 nixos-rebuild dry-build --flake ".#${HOST}" -vvv 2>&1 | grep 'evaluating file' 
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

.PHONY: update-all
update-all: update update-ghostty update-neovim ## Update all packages

.PHONY: update-flake
update-flake: ## Update nix packages
	nix --extra-experimental-features 'nix-command flakes' flake update

.PHONY: update-claude-code
update-claude-code: ## Update the claude-code flake
	nix flake update claude-code 

.PHONY: update-ghostty
update-ghostty: ## Update the ghostty flake
	nix flake update ghostty

.PHONY: update-neovim
update-neovim: ## Update the neovim flake
	nix flake update neovim

.PHONY: update-minecraft
update-minecraft: ## Update nix-minecraft flake
	nix flake update nix-minecraft

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
gc: ##  Garbage collect nix files that are older than 3 days.
	@echo "$(DATELOG) Garbage collecting nix files older than 3 days"
	sudo nix-collect-garbage --delete-older-than 3d
	sudo nix-env --delete-generations 3d
	sudo nix-store --gc

.PHONY: fmt
fmt: ## format nix files
	@echo "$(DATELOG) Formatting nix files"
	alejandra --quiet .

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


