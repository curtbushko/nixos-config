# NixOS Config - Project Instructions

## Repository Overview

This is a Snowfall-lib based NixOS/nix-darwin/home-manager configuration managing multiple machines across Linux and macOS.

## Directory Structure

```
nixos-config/
├── flake.nix              # Entry point with inputs/outputs
├── flake.lock             # Pinned dependencies
├── Taskfile.yml           # Task runner (replaces Makefile)
├── systems/               # Per-machine system configs
│   ├── x86_64-linux/      # NixOS machines (gamingrig, node00-02)
│   └── aarch64-darwin/    # macOS machines (m1-air, m4-pro, work laptop)
├── homes/                 # Per-user home-manager configs
│   ├── x86_64-linux/      # Linux users
│   └── aarch64-darwin/    # macOS users
├── modules/
│   ├── nixos/             # NixOS-specific modules (services, hardware)
│   ├── darwin/            # macOS-specific modules
│   └── home/              # Cross-platform home-manager modules
├── packages/              # Custom Nix packages
└── secrets/               # Encrypted secrets (sops-nix with age)
```

## Build Commands

All operations use `task` (go-task). The `make` command is aliased to `task`.

```bash
task switch      # Build and apply configuration (auto-detects host type)
task test        # Test configuration without switching
task fmt         # Format all Nix files with alejandra
task update-all  # Update all flake inputs
task gc          # Garbage collect (3+ days old)
task -l          # List all available tasks
```

## Module Pattern

All modules follow this structure with the `ns` namespace:

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.modulename;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.ns.modulename = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable modulename";
    };
  };

  config = mkIf cfg.enable {
    # Configuration here
    home.packages = [ pkgs.somepackage ]
      ++ (lib.optionals isDarwin [ pkgs.darwin-only ])
      ++ (lib.optionals isLinux [ pkgs.linux-only ]);
  };
}
```

## Nix Style Rules

### Package References - ALWAYS Explicit

```nix
# CORRECT - explicit references
home.packages = [ pkgs.git pkgs.vim pkgs.wget ];

# WRONG - implicit scope with 'with'
home.packages = with pkgs; [ git vim wget ];
```

### Platform Conditionals

```nix
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  home.packages = [ pkgs.common-package ]
    ++ (lib.optionals isDarwin [ pkgs.macos-only ])
    ++ (lib.optionals isLinux [ pkgs.linux-only ]);
}
```

### Flake Inputs - Follow nixpkgs

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  some-flake = {
    url = "github:owner/repo";
    inputs.nixpkgs.follows = "nixpkgs";  # Avoid duplicate nixpkgs
  };
};
```

### System Configs - Enable Modules

System configs in `systems/` enable modules from `modules/nixos/`:

```nix
ns = {
  hardware.audio.enable = true;
  hardware.cpu.enable = true;
  services.wm.enable = true;
  services.llm.enable = true;
};
```

### Home Configs - Enable Modules

Home configs in `homes/` enable modules from `modules/home/`:

```nix
ns = {
  browsers.enable = true;
  gaming.enable = true;
  llm.enable = true;
  shells.enable = true;
  tools.enable = true;
  wm.enable = true;
};
```

## Secrets Management

Uses sops-nix with age encryption:

```nix
# In modules/home/secrets/default.nix
sops.defaultSopsFile = ../../../secrets/secrets.yaml;
sops.defaultSopsFormat = "yaml";
sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

# Define secrets
sops.secrets."hosts/gamingrig/tailnet_id" = {};
```

Age key location: `~/.config/sops/age/keys.txt`

## File Naming Conventions

- Module directories: lowercase with hyphens (`go-team/`, `node-team/`)
- Module files: lowercase with hyphens (`hardware-configuration.nix`)
- System configs: `systems/{arch}/{hostname}/default.nix`
- Home configs: `homes/{arch}/{user}@{hostname}/default.nix`

## Testing Changes

1. **Format first**: `task fmt`
2. **Test build**: `task test` (builds without switching)
3. **Switch**: `task switch` (builds and activates)

## Common Patterns

### Adding a New Package to Home

Edit the relevant module in `modules/home/`:

```nix
home.packages = [
  pkgs.existing-package
  pkgs.new-package  # Add here
];
```

### Adding a New System Module

1. Create `modules/nixos/services/newservice/default.nix`
2. Follow the module pattern with `ns.services.newservice.enable`
3. Enable in relevant system config: `ns.services.newservice.enable = true;`

### Adding a New Home Module

1. Create `modules/home/newmodule/default.nix`
2. Follow the module pattern with `ns.newmodule.enable`
3. Add import to parent module's `default.nix`
4. Enable in relevant home config

## Host Types

Defined in `Taskfile.yml`:

| Host Type | Examples | Build Command |
|-----------|----------|---------------|
| NixOS | gamingrig, node00-02 | `nixos-rebuild switch` |
| Darwin | m1-air, m4-pro, work laptop | `darwin-rebuild switch` |
| Home-only | steamdeck | `home-manager switch` |

## Formatting

Use alejandra (opinionated Nix formatter):

```bash
task fmt           # Format all files
alejandra file.nix # Format single file
```

## Implementation Ladder

Before writing Nix code, stop at the first rung that holds:

1. **Does this need to exist?** → skip it (YAGNI)
2. **Already in this codebase?** → reuse the existing module
3. **Nixpkgs has it?** → use `pkgs.packagename`
4. **Home-manager option?** → use `programs.X` or `services.X`
5. **One line?** → one line
6. **Only then:** create a new module

## Anti-Patterns

- Using `with pkgs;` (use explicit `pkgs.X` references)
- Creating modules without the `ns` namespace
- Hardcoding paths (use `config.home.homeDirectory`, `config.xdg.configHome`)
- Not following nixpkgs in flake inputs
- Using `rm` to delete files (move to `.trash/` instead)
- Creating `.gitkeep` files
