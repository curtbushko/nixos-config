NIXOS_CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
OS := $(shell uname | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | tr '[:upper:]' '[:lower:]')
HOST := $(shell hostname -s)
DATELOG := "[$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')]"

# Define host types
DARWIN_HOSTS := curtbushko-X3FR7279D2 m4-pro m1-air
NIXOS_HOSTS := gamingrig node00 node01 node02
HOME_MANAGER_HOSTS := steamdeck relay

# Set NIXUSER based on hostname
ifeq ($(HOST),steamdeck)
NIXUSER := deck
else
NIXUSER ?= curtbushko
endif

.PHONY: default
default: switch

.PHONY: setup
setup: ## Setup nix on darwin and home-manager hosts.
ifneq (,$(findstring $(HOST),$(DARWIN_HOSTS)))
	@echo "$(DATELOG) Installing Determinate Nix Installer for Darwin..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
else ifneq (,$(findstring $(HOST),$(HOME_MANAGER_HOSTS)))
	@echo "$(DATELOG) Installing Nix Installer for home-manager..."
	sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
else ifneq (,$(findstring $(HOST),$(NIXOS_HOSTS)))
	@echo "$(DATELOG) Setup not needed for NixOS hosts (Nix is pre-installed)"
else
	@echo "$(DATELOG) ERROR: Unknown host '$(HOST)'. Please add it to DARWIN_HOSTS, NIXOS_HOSTS, or HOME_MANAGER_HOSTS in the Makefile."
	@exit 1
endif

.PHONY: switch
switch: ## Build and switch your nix config.
	@echo "$(DATELOG) Building nix config for $(HOST)"
ifneq (,$(findstring $(HOST),$(DARWIN_HOSTS)))
	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${HOST}.system" --show-trace --impure
	sudo ./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${HOST}" --impure
else ifneq (,$(findstring $(HOST),$(NIXOS_HOSTS)))
	sudo NIXPKGS_ALLOW_UNSUPPORTED_ARCH=1 nixos-rebuild switch --flake ".#${HOST}" --impure
else ifneq (,$(findstring $(HOST),$(HOME_MANAGER_HOSTS)))
	@echo "$(DATELOG) Using home-manager for ${NIXUSER}@${HOST}"
	@rm -f ~/.*.backup ~/.config/**/*.backup || true
	nix --extra-experimental-features 'nix-command flakes' run nixpkgs#home-manager -- switch --flake ".#${NIXUSER}@${HOST}" -b backup --impure
else
	@echo "$(DATELOG) ERROR: Unknown host '$(HOST)'. Please add it to DARWIN_HOSTS, NIXOS_HOSTS, or HOME_MANAGER_HOSTS in the Makefile."
	@exit 1
endif

.PHONY: dry-build
dry-build: ## Build and switch your nix config.
	@echo "$(DATELOG) Building dry build of nix config"
ifneq (,$(findstring $(HOST),$(DARWIN_HOSTS)))
	@echo "$(DATELOG) Dry build not supported for Darwin hosts"
else ifneq (,$(findstring $(HOST),$(NIXOS_HOSTS)))
	sudo NIXPKGS_ALLOW_UNSUPPORTED_ARCH=1 nixos-rebuild dry-build --flake ".#${HOST}" --impure -vvv 2>&1 | grep 'evaluating file'
else ifneq (,$(findstring $(HOST),$(HOME_MANAGER_HOSTS)))
	@echo "$(DATELOG) Dry build not applicable for home-manager hosts"
else
	@echo "$(DATELOG) ERROR: Unknown host '$(HOST)'. Please add it to DARWIN_HOSTS, NIXOS_HOSTS, or HOME_MANAGER_HOSTS in the Makefile."
	@exit 1
endif

.PHONY: test
test: ## Test your nix config.
	@echo "$(DATELOG) Testing nix config"
ifneq (,$(findstring $(HOST),$(DARWIN_HOSTS)))
	nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.${HOST}.system" --show-trace --impure
	./result/sw/bin/darwin-rebuild test --flake "$$(pwd)#${HOST}" --impure
else ifneq (,$(findstring $(HOST),$(NIXOS_HOSTS)))
	sudo NIXPKGS_ALLOW_UNSUPPORTED_ARCH=1 nixos-rebuild test --flake ".#${HOST}" --impure
else ifneq (,$(findstring $(HOST),$(HOME_MANAGER_HOSTS)))
	@echo "$(DATELOG) Testing home-manager config for ${NIXUSER}@${HOST}"
	nix --extra-experimental-features 'nix-command flakes' run nixpkgs#home-manager -- build --flake ".#${NIXUSER}@${HOST}" --impure
else
	@echo "$(DATELOG) ERROR: Unknown host '$(HOST)'. Please add it to DARWIN_HOSTS, NIXOS_HOSTS, or HOME_MANAGER_HOSTS in the Makefile."
	@exit 1
endif

.PHONY: update-all
update-all: update update-llm-agents update-ghostty update-neovim update-minecraft update-vicinae ## Update all packages

.PHONY: update-flake
update-flake: ## Update nix packages
	nix --extra-experimental-features 'nix-command flakes' flake update

.PHONY: update-claude-code
update-claude-code: ## Update the claude-code flake
	nix flake update claude-code

.PHONY: update-ghostty
update-ghostty: ## Update the ghostty flake
	nix flake update ghostty

.PHONY: update-llm-agents
update-llm-agents: ## Update the llm-agents flake
	nix flake update llm-agents

.PHONY: update-minecraft
update-minecraft: ## Update minecraft-servers flake
	nix flake update minecraft-servers

.PHONY: update-neovim
update-neovim: ## Update the neovim flake
	nix flake update neovim

.PHONY: update-vicinae
update-vicinae: ## Update vicinae flake
	nix flake update vicinae

.PHONY: update-worktrunk
update-worktrunk: ## Update worktrunk flake
	nix flake update worktrunk

# VM build settings
GAMINGRIG_REMOTE_PATH ?= ~/workspace/github.com/curtbushko/nixos-config
VM_DEST_DIR ?= ~/VMs/gamingrig-vm

.PHONY: build-vm
build-vm: ## Build aarch64-linux VM for Apple Silicon (run on gamingrig)
	@echo "$(DATELOG) Building aarch64-linux VM (gamingrig-vm)"
ifneq (,$(findstring $(HOST),gamingrig))
	nix build ".#nixosConfigurations.gamingrig-vm.config.system.build.vm" --show-trace -o outdir/vm
	@echo "$(DATELOG) VM built successfully. Run with: outdir/vm/bin/run-gamingrig-vm-vm"
else
	@echo "$(DATELOG) ERROR: This target must be run on gamingrig (requires binfmt for aarch64)"
	@exit 1
endif

.PHONY: copy-vm
copy-vm: ## Copy built VM from gamingrig to Mac (run on Mac)
	@echo "$(DATELOG) Copying VM from $(GAMINGRIG_TAILNET_ID) to $(VM_DEST_DIR)"
ifneq (,$(findstring $(HOST),$(DARWIN_HOSTS)))
	mkdir -p $(VM_DEST_DIR)
	rsync -avz --progress $(GAMINGRIG_TAILNET_ID):$(GAMINGRIG_REMOTE_PATH)/outdir/vm/ $(VM_DEST_DIR)/
	@echo "$(DATELOG) VM copied to $(VM_DEST_DIR)"
	@echo "$(DATELOG) Run with: $(VM_DEST_DIR)/bin/run-gamingrig-vm-vm"
else
	@echo "$(DATELOG) ERROR: This target should be run on a Darwin host"
	@exit 1
endif

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
	@if [ -e ./outdir ]; then \
		mkdir -p .trash && \
		(grep -q "^\.trash/$$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore) && \
		mv ./outdir .trash/outdir-$$(date +%Y%m%d-%H%M%S) && \
		echo "$(DATELOG) Moved ./outdir to .trash/"; \
	fi

.PHONY: fmt
fmt: ## format nix files
	@echo "$(DATELOG) Formatting nix files"
	alejandra --quiet .

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


