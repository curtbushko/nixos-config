# Modular Nix Configuration Patterns

## Why Modularize?

- **Reusability**: Share configs across machines
- **Organization**: Logical separation of concerns
- **Toggleability**: Enable/disable features per host
- **Maintainability**: Easier to update and debug

## Directory Structure Patterns

### Snowfall-style (Recommended)
Based on [Snowfall Lib](https://snowfall.org/) and configs like curtbushko/nixos-config:

```
nixos-config/
├── flake.nix
├── systems/
│   ├── x86_64-linux/
│   │   ├── desktop/default.nix
│   │   └── server/default.nix
│   └── aarch64-darwin/
│       └── macbook/default.nix
├── modules/
│   ├── nixos/           # NixOS-only modules
│   │   ├── services/
│   │   └── desktop/
│   ├── darwin/          # macOS-only modules
│   │   └── homebrew/
│   └── home/            # Cross-platform (home-manager)
│       ├── shell/
│       ├── editors/
│       └── dev/
├── homes/               # Per-user home-manager configs
│   ├── x86_64-linux/
│   │   └── user@desktop/default.nix
│   └── aarch64-darwin/
│       └── user@macbook/default.nix
├── packages/            # Custom packages
├── overlays/            # Nixpkgs overlays
└── secrets/             # Encrypted secrets
```

### Simple Flat Structure
For smaller configs:
```
nixos-config/
├── flake.nix
├── configuration.nix
├── hardware-configuration.nix
├── home.nix
└── modules/
    ├── git.nix
    ├── zsh.nix
    └── neovim.nix
```

## Module Basics

A module is a function that returns an attribute set:

```nix
# modules/home/git.nix
{ config, lib, pkgs, ... }:

{
  # Option definitions
  programs.git = {
    enable = true;
    userName = "Your Name";
  };
}
```

### Module Arguments

```nix
{ config, lib, pkgs, options, specialArgs, modulesPath, ... }:

# config      - Final merged configuration
# lib         - Nixpkgs lib functions
# pkgs        - Nixpkgs packages
# options     - All available options
# specialArgs - Extra args from specialArgs
# modulesPath - Path to NixOS modules
```

## Custom Options Pattern

Create toggleable, configurable modules:

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
      description = "Git email";
    };
    
    signing = {
      enable = lib.mkEnableOption "GPG commit signing";
      key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "GPG signing key ID";
      };
    };
    
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Extra git config";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = cfg.userName;
      userEmail = cfg.userEmail;
      signing = lib.mkIf cfg.signing.enable {
        signByDefault = true;
        key = cfg.signing.key;
      };
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      } // cfg.extraConfig;
    };
  };
}
```

Usage:
```nix
# homes/user@hostname/default.nix
{
  imports = [ ../../modules/home/git ];
  
  custom.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
    signing = {
      enable = true;
      key = "ABCD1234";
    };
  };
}
```

## Import Patterns

### Direct Import
```nix
{
  imports = [
    ./modules/git.nix
    ./modules/zsh.nix
    ./modules/neovim.nix
  ];
}
```

### Default.nix Aggregation
```nix
# modules/home/default.nix
{
  imports = [
    ./git
    ./zsh
    ./neovim
  ];
}

# Then in flake or home.nix:
{
  imports = [ ./modules/home ];
}
```

### Conditional Imports
```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    ./linux-only.nix
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    ./darwin-only.nix
  ];
}
```

## Passing Arguments

### specialArgs (Recommended)
```nix
# flake.nix
{
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      specialArgs = { 
        inherit inputs;
        myCustomVar = "value";
      };
      modules = [ ./configuration.nix ];
    };
  };
}

# configuration.nix
{ inputs, myCustomVar, ... }:
{
  # Use inputs.home-manager, etc.
}
```

### _module.args (Alternative)
```nix
{
  _module.args = {
    myArg = "value";
  };
}
```

## Host-Specific Overrides

```nix
# modules/home/git/default.nix (base module)
{
  custom.git = {
    enable = lib.mkDefault true;  # Can be overridden
    userName = lib.mkDefault "Default Name";
  };
}

# homes/user@work-laptop/default.nix
{
  custom.git.userEmail = "work@company.com";  # Override
}

# homes/user@personal-laptop/default.nix
{
  custom.git.userEmail = "personal@email.com";  # Override
}
```

## Priority and Merging

```nix
{
  # mkDefault - Low priority (easily overridden)
  option = lib.mkDefault "value";
  
  # mkForce - High priority (overrides most things)
  option = lib.mkForce "value";
  
  # mkOverride N - Explicit priority (lower = higher priority)
  option = lib.mkOverride 100 "value";  # Default is 100
  option = lib.mkOverride 50 "value";   # Higher priority
  
  # mkOrder for lists
  list = lib.mkBefore [ "first" ];  # Prepend
  list = lib.mkAfter [ "last" ];    # Append
}
```

## Common Module Types

### Service Module (NixOS)
```nix
{ config, lib, pkgs, ... }:
let cfg = config.services.myService;
in {
  options.services.myService = {
    enable = lib.mkEnableOption "My Service";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.myService = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.myPackage}/bin/myservice --port ${toString cfg.port}";
      };
    };
  };
}
```

### Program Module (Home Manager)
```nix
{ config, lib, pkgs, ... }:
let cfg = config.programs.myProgram;
in {
  options.programs.myProgram = {
    enable = lib.mkEnableOption "My Program";
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.myProgram ];
    xdg.configFile."myprogram/config.json".text = builtins.toJSON cfg.settings;
  };
}
```

### Feature Toggle Module
```nix
{ config, lib, pkgs, ... }:
let cfg = config.features.gaming;
in {
  options.features.gaming = {
    enable = lib.mkEnableOption "Gaming support";
  };

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;
  };
}
```

## Best Practices

1. **One concern per module** - Don't mix unrelated configs
2. **Use lib.mkEnableOption** - For toggleable features
3. **Use lib.mkDefault** - For overridable defaults
4. **Namespace custom options** - Use `custom.*` or `my.*`
5. **Document options** - Add descriptions to mkOption
6. **Test incrementally** - Build after each major change
7. **Avoid `with pkgs`** - Be explicit for clarity
