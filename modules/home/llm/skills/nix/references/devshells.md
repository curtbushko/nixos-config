# Nix Development Shells Best Practices

## Overview

Development shells provide isolated, reproducible development environments.

| Command | Era | File | Notes |
|---------|-----|------|-------|
| `nix-shell` | Pre-flakes | `shell.nix` | Still widely used |
| `nix develop` | Flakes | `flake.nix` | Recommended for new projects |

## Basic Flake devShell

```nix
{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_20
            yarn
            nodePackages.typescript
          ];

          shellHook = ''
            echo "Node.js development environment"
            echo "Node: $(node --version)"
          '';
        };
      }
    );
}
```

## mkShell Options

```nix
pkgs.mkShell {
  # Packages available in the shell
  packages = [ pkgs.git pkgs.curl ];
  
  # Alternative: buildInputs for libraries your code links against
  buildInputs = [ pkgs.openssl pkgs.zlib ];
  
  # Tools needed at build time (compilers, pkg-config, etc.)
  nativeBuildInputs = [ pkgs.pkg-config pkgs.cmake ];
  
  # Environment variables
  MY_VAR = "value";
  DATABASE_URL = "postgres://localhost/dev";
  
  # Script to run when entering the shell
  shellHook = ''
    export PATH="$PWD/node_modules/.bin:$PATH"
    echo "Welcome to the dev shell!"
  '';
  
  # Use a specific shell (default: bash)
  # shellHook = "exec ${pkgs.zsh}/bin/zsh";
}
```

## Multiple Shells

```nix
{
  devShells = {
    default = pkgs.mkShell { packages = [ pkgs.nodejs ]; };
    python = pkgs.mkShell { packages = [ pkgs.python3 pkgs.poetry ]; };
    rust = pkgs.mkShell { packages = [ pkgs.rustc pkgs.cargo ]; };
  };
}
```

```bash
nix develop        # Uses default
nix develop .#python
nix develop .#rust
```

## Language-Specific Examples

### Node.js
```nix
pkgs.mkShell {
  packages = with pkgs; [
    nodejs_20
    yarn
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.typescript-language-server
  ];
  shellHook = ''
    export PATH="$PWD/node_modules/.bin:$PATH"
  '';
}
```

### Python
```nix
pkgs.mkShell {
  packages = with pkgs; [
    python311
    python311Packages.pip
    python311Packages.virtualenv
    poetry
    ruff
    pyright
  ];
  shellHook = ''
    export PYTHONDONTWRITEBYTECODE=1
  '';
}
```

### Rust
```nix
let
  rust-overlay = inputs.rust-overlay;
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ rust-overlay.overlays.default ];
  };
in pkgs.mkShell {
  packages = with pkgs; [
    (rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" "clippy" "rustfmt" ];
    })
    rust-analyzer
    cargo-watch
  ];
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
}
```

### Go
```nix
pkgs.mkShell {
  packages = with pkgs; [
    go_1_21
    gopls
    golangci-lint
    delve
  ];
  shellHook = ''
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
  '';
}
```

## Using Overlays

```nix
let
  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        nodejs = prev.nodejs_20;
        myTool = prev.callPackage ./my-tool.nix {};
      })
    ];
  };
in pkgs.mkShell {
  packages = [ pkgs.nodejs pkgs.myTool ];
}
```

## Direnv Integration

Create `.envrc` in project root:
```bash
use flake
```

Or with options:
```bash
use flake . --impure
watch_file flake.nix
watch_file flake.lock
```

Enable direnv:
```bash
direnv allow
```

### nix-direnv (Recommended)

Install nix-direnv for faster shell loading:
```nix
# In home-manager
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;  # Caches environments
};
```

## Legacy shell.nix

For non-flake projects:
```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    nodejs
    yarn
  ];
}
```

Enter with:
```bash
nix-shell
```

## Pinning Dependencies

### In Flakes
Dependencies are automatically pinned via `flake.lock`.

### In shell.nix
```nix
let
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/abc123.tar.gz";
    sha256 = "sha256:...";
  };
  pkgs = import nixpkgs { config = {}; overlays = []; };
in pkgs.mkShell { ... }
```

## Preventing Garbage Collection

Pin devshell dependencies:
```bash
nix develop --profile ./.nix-profile
```

Or use nix-direnv which caches automatically.

## devenv (Higher-Level Abstraction)

[devenv](https://devenv.sh/) provides a simpler interface:

```nix
# devenv.nix
{ pkgs, ... }:
{
  packages = [ pkgs.git ];
  
  languages.python = {
    enable = true;
    version = "3.11";
    poetry.enable = true;
  };
  
  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "mydb"; }];
  };
  
  scripts.dev.exec = "python manage.py runserver";
}
```

## Common Patterns

### Cross-Platform Shells
```nix
let
  pkgs = import nixpkgs { inherit system; };
  darwinPackages = with pkgs; lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.CoreServices
  ];
in pkgs.mkShell {
  packages = [ pkgs.git ] ++ darwinPackages;
}
```

### Inheriting from Package
```nix
# Use the build environment of a package
pkgs.myPackage.overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.gdb ];
})
```

### Temporary Shell
```bash
# Quick one-off shell
nix-shell -p nodejs yarn

# With flakes
nix shell nixpkgs#nodejs nixpkgs#yarn
```
