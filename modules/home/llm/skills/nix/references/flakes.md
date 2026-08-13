# Nix Flakes Best Practices

## Flake Structure

Every flake consists of:
- `flake.nix` - The flake definition
- `flake.lock` - Auto-generated version lock file

```nix
{
  description = "Description of your flake";

  inputs = {
    # Input declarations
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # Output declarations
  };
}
```

## Input Best Practices

### Pin to Specific Branches
```nix
inputs = {
  # Stable release
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  
  # Unstable (rolling)
  nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  
  # Specific commit for reproducibility
  nixpkgs-pinned.url = "github:NixOS/nixpkgs/abc123def456";
};
```

### Avoid Duplicate Inputs with `follows`
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";  # Use same nixpkgs
  };
  
  # Multiple follows
  neovim-flake = {
    url = "github:user/neovim-config";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
};
```

### Input Types
```nix
inputs = {
  # GitHub (most common)
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  
  # GitLab
  myflake.url = "gitlab:user/repo";
  
  # Local path
  local.url = "path:./subfolder";
  
  # Tarball
  tarball.url = "https://example.com/flake.tar.gz";
  
  # Non-flake input
  flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;  # Not evaluated as flake
  };
};
```

## Output Schema

```nix
outputs = { self, nixpkgs, ... }: {
  # NixOS configurations
  nixosConfigurations.<hostname> = nixpkgs.lib.nixosSystem { ... };
  
  # nix-darwin configurations
  darwinConfigurations.<hostname> = darwin.lib.darwinSystem { ... };
  
  # Home-manager configurations (standalone)
  homeConfigurations."user@host" = home-manager.lib.homeManagerConfiguration { ... };
  
  # Packages
  packages.<system>.<name> = derivation;
  packages.<system>.default = derivation;  # `nix build`
  
  # Development shells
  devShells.<system>.<name> = derivation;
  devShells.<system>.default = derivation;  # `nix develop`
  
  # Apps
  apps.<system>.<name> = { type = "app"; program = "..."; };
  
  # Overlays
  overlays.<name> = final: prev: { ... };
  overlays.default = final: prev: { ... };
  
  # NixOS/Darwin/Home-manager modules
  nixosModules.<name> = { ... };
  darwinModules.<name> = { ... };
  homeManagerModules.<name> = { ... };
  
  # Templates
  templates.<name> = { path = ./template; description = "..."; };
  
  # Checks (run with `nix flake check`)
  checks.<system>.<name> = derivation;
};
```

## Multi-System Pattern

```nix
outputs = { self, nixpkgs, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.default = pkgs.hello;
      devShells.default = pkgs.mkShell {
        packages = [ pkgs.git pkgs.vim ];
      };
    }
  ) // {
    # Non-system-specific outputs
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem { ... };
  };
```

## Without flake-utils

```nix
outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    packages = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in { default = pkgs.hello; }
    );
  };
```

## Updating Flakes

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake update home-manager

# Show current versions
nix flake metadata

# Show input tree
nix flake metadata --json | jq '.locks.nodes'
```

## Lock File Management

- **Commit `flake.lock`** to version control for reproducibility
- Review lock file changes in PRs
- Pin to commits for critical production systems
- Use `--recreate-lock-file` to reset all pins

## Flake Checks

```nix
outputs = { self, nixpkgs, ... }: {
  checks.x86_64-linux = {
    # Build test
    build = self.packages.x86_64-linux.default;
    
    # Format check
    formatting = pkgs.runCommand "check-formatting" {} ''
      ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${self}
      touch $out
    '';
    
    # NixOS VM test
    vmTest = nixpkgs.lib.nixos.runTest {
      name = "my-test";
      nodes.machine = { ... }: { };
      testScript = ''
        machine.wait_for_unit("default.target")
      '';
    };
  };
};
```

## Common Issues

### "file not found" errors
Files must be tracked by git:
```bash
git add flake.nix flake.lock
```

### Pure evaluation errors
Flakes enforce pure evaluation. Use `--impure` flag only when necessary:
```bash
nix build --impure
```

### Registry vs Lock
- **Registry**: Resolves symbolic names (e.g., `nixpkgs` → `github:NixOS/nixpkgs`)
- **Lock file**: Pins specific commits for reproducibility
