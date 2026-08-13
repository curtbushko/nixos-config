# Nix Package Searching

## Command Line Search

### nix search (Flakes)
```bash
# Search all packages
nix search nixpkgs packagename

# Show all packages (use ^ to avoid highlighting everything)
nix search nixpkgs ^

# Search with regex
nix search nixpkgs 'firefox|chromium'

# Search multiple terms (AND)
nix search nixpkgs git frontend

# Search specific attribute path
nix search nixpkgs#python3Packages numpy

# Exclude results
nix search nixpkgs neovim --exclude 'python|gui'

# JSON output (for scripting)
nix search nixpkgs nodejs --json | jq
```

### nix-env (Legacy)
```bash
# Search by attribute name
nix-env -qaP firefox

# Search with description
nix-env -qaP --description firefox
```

Note: `nix search` is slow on first run (downloads nixpkgs index). Subsequent runs use cache.

## Web-Based Search

### [search.nixos.org](https://search.nixos.org)
- Best for browsing packages
- Shows package version, description, homepage
- Supports release channels (unstable, 24.11, etc.)
- Filter by installed programs

### [search.nixos.org/options](https://search.nixos.org/options)
- Search NixOS configuration options
- Shows option type, default, description

### [home-manager-options.extranix.com](https://home-manager-options.extranix.com)
- Search Home Manager options

### [mynixos.com](https://mynixos.com)
- Packages, NixOS options, home-manager options

## CLI Tools

### nix-search-cli
Search from command line using search.nixos.org API:
```bash
nix run github:peterldowns/nix-search-cli -- python linter

# Search by program name
nix-search -p gcloud
```

### diamondburned/nix-search
Fast local search with index:
```bash
nix-search --index  # Build index (first time)
nix-search firefox
```

## Finding a Package

### By Program Name
If you know the binary name but not the package:
```bash
# Using search.nixos.org "Programs" filter
# Or nix-search-cli:
nix-search -p kubectl
```

### Using the REPL
```bash
nix repl '<nixpkgs>'

# Tab completion
nix-repl> python3<TAB>
nix-repl> python3Packages.num<TAB>

# Check package attributes
nix-repl> python3.version
nix-repl> python3.meta.description
```

### Searching Nested Packages
```bash
# Python packages
nix search nixpkgs#python3Packages requests

# Node packages
nix search nixpkgs#nodePackages typescript

# Haskell packages
nix search nixpkgs#haskellPackages pandoc

# Vim plugins
nix search nixpkgs#vimPlugins telescope
```

## Package Metadata

```bash
# Show package info
nix eval nixpkgs#firefox.meta --json | jq

# Get version
nix eval nixpkgs#firefox.version

# Get homepage
nix eval nixpkgs#firefox.meta.homepage

# Get maintainers
nix eval nixpkgs#firefox.meta.maintainers --json
```

## Finding Package Sources

```bash
# Open package definition in editor
nix edit nixpkgs#firefox

# Get store path without building
nix eval nixpkgs#firefox.outPath

# Show package derivation
nix show-derivation nixpkgs#firefox
```

## Comparing Versions

```bash
# Show version in different channels
nix eval github:NixOS/nixpkgs/nixos-24.11#firefox.version
nix eval github:NixOS/nixpkgs/nixos-unstable#firefox.version
```

## Flake Package Discovery

```bash
# Show all outputs of a flake
nix flake show github:user/repo

# Show packages specifically
nix flake show github:NixOS/nixpkgs --legacy  # --legacy for legacyPackages
```

## Common Package Paths

| Type | Path |
|------|------|
| Regular packages | `pkgs.packageName` |
| Python packages | `pkgs.python3Packages.name` |
| Node packages | `pkgs.nodePackages.name` |
| Haskell packages | `pkgs.haskellPackages.name` |
| Rust packages | `pkgs.rustPackages.name` |
| Vim plugins | `pkgs.vimPlugins.name` |
| VS Code extensions | `pkgs.vscode-extensions.publisher.name` |
| NerdFonts | `pkgs.nerdfonts` (override with `fonts` list) |

## Tips

### Package Not Found?
1. Check spelling (use tab completion)
2. Try different search terms
3. Check if it's in a nested attribute set (python3Packages, nodePackages)
4. It might not exist in nixpkgs—check upstream

### Multiple Versions
Some packages have version suffixes:
```bash
nix search nixpkgs nodejs
# Shows: nodejs, nodejs_18, nodejs_20, nodejs_22
```

### Unfree Packages
Some packages require allowing unfree:
```nix
{
  nixpkgs.config.allowUnfree = true;
}
```

Or per-command:
```bash
NIXPKGS_ALLOW_UNFREE=1 nix search nixpkgs --impure vscode
```
