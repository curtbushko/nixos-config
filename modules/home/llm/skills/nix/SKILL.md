---
name: nix
description: Comprehensive Nix best practices for flakes, NixOS, home-manager, nix-darwin, devshells, package management, and system configuration. Use this skill when working with Nix flakes, NixOS configuration, home-manager dotfiles, nix-darwin macOS setup, development shells (nix develop/nix-shell), package searching, testing, overlays, or any Nix-related tasks including debugging derivations and garbage collection.
---

# Nix Best Practices Skill

This skill provides best practices and patterns for working with Nix, including flakes, NixOS, home-manager, nix-darwin, and development environments.

## Quick Reference

| Task | Reference |
|------|-----------|
| Flakes & inputs | [references/flakes.md](references/flakes.md) |
| Home-manager | [references/home-manager.md](references/home-manager.md) |
| nix-darwin (macOS) | [references/darwin.md](references/darwin.md) |
| Development shells | [references/devshells.md](references/devshells.md) |
| Package searching | [references/searching.md](references/searching.md) |
| Testing & debugging | [references/testing.md](references/testing.md) |
| Garbage collection | [references/maintenance.md](references/maintenance.md) |
| Modular config patterns | [references/modules.md](references/modules.md) |

## Core Principles

### 1. Use Flakes for Reproducibility
Always prefer flakes over channels for new projects. Flakes provide:
- Pinned dependencies via `flake.lock`
- Hermetic evaluation (no NIX_PATH dependencies)
- Standardized project structure
- Composable inputs and outputs

### 2. Enable Flakes
```nix
# In configuration.nix or nix.conf
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### 3. Directory Structure (Snowfall-style Pattern)
Based on real-world configs like curtbushko/nixos-config:
```
nixos-config/
├── flake.nix           # Entry point
├── flake.lock          # Pinned dependencies
├── systems/            # Per-machine configs
│   ├── x86_64-linux/
│   │   └── hostname/default.nix
│   └── aarch64-darwin/
│       └── hostname/default.nix
├── modules/
│   ├── nixos/          # NixOS-specific modules
│   ├── darwin/         # macOS-specific modules
│   └── home/           # Home-manager (cross-platform)
├── homes/              # Per-user home-manager configs
├── packages/           # Custom packages
└── secrets/            # Encrypted secrets (sops-nix)
```

### 4. Configuration Layering
Configurations build up in layers, each can override the previous:
- **Linux**: flake.nix → systems → modules/nixos → modules/home
- **macOS**: flake.nix → systems → modules/darwin → modules/home

### 5. Avoid Common Anti-patterns
```nix
# BAD: Implicit scope with `with`
environment.systemPackages = with pkgs; [ git vim wget ];

# GOOD: Explicit references
environment.systemPackages = [ pkgs.git pkgs.vim pkgs.wget ];
# Or use a let binding
environment.systemPackages = let p = pkgs; in [ p.git p.vim p.wget ];
```

## Essential Commands

```bash
# Build and switch NixOS configuration
sudo nixos-rebuild switch --flake .#hostname

# Build and switch nix-darwin
darwin-rebuild switch --flake .#hostname

# Build home-manager standalone
home-manager switch --flake .#user@hostname

# Update all flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Search packages
nix search nixpkgs packagename

# Enter development shell
nix develop

# Garbage collection (with generation cleanup)
sudo nix-collect-garbage -d --delete-older-than 7d

# Show flake outputs
nix flake show

# Check flake for errors
nix flake check
```

## Basic Flake Template

```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";  # Avoid duplicate nixpkgs
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };  # Pass inputs to modules
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.username = import ./home.nix;
        }
      ];
    };
  };
}
```

## Module Pattern with Options

```nix
# modules/home/git/default.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.git;
in {
  options.custom.git = {
    enable = lib.mkEnableOption "Git configuration";
    userName = lib.mkOption {
      type = lib.types.str;
      description = "Git user name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git user email";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = cfg.userName;
      userEmail = cfg.userEmail;
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
  };
}
```

## Secrets Management with sops-nix

```nix
# In flake.nix inputs
sops-nix.url = "github:Mic92/sops-nix";

# In configuration
sops = {
  defaultSopsFile = ./secrets/secrets.yaml;
  age.keyFile = "/var/lib/sops-nix/key.txt";
  secrets.my-secret = {};
};
```

## Key Libraries

| Library | Purpose |
|---------|---------|
| [Snowfall Lib](https://snowfall.org/) | Standardized config structure |
| [sops-nix](https://github.com/Mic92/sops-nix) | Encrypted secrets in git |
| [home-manager](https://github.com/nix-community/home-manager) | User environment management |
| [nix-darwin](https://github.com/LnL7/nix-darwin) | macOS declarative config |
| [flake-utils](https://github.com/numtide/flake-utils) | Multi-system helpers |
| [devenv](https://devenv.sh/) | Simplified dev environments |

## When to Use What

- **NixOS modules**: System-wide packages, services, boot config
- **home-manager**: User dotfiles, user packages, per-user services
- **nix-darwin**: macOS system config (Homebrew, defaults, launchd)
- **devShells**: Project-specific development environments
- **overlays**: Package modifications, version pins, custom builds

## See Reference Files

For detailed guidance on specific topics, consult the reference files:
- **Flakes deep-dive**: `references/flakes.md`
- **Home-manager patterns**: `references/home-manager.md`
- **macOS with nix-darwin**: `references/darwin.md`
- **Development shells**: `references/devshells.md`
- **Finding packages**: `references/searching.md`
- **Testing configurations**: `references/testing.md`
- **Garbage collection**: `references/maintenance.md`
- **Modular patterns**: `references/modules.md`
