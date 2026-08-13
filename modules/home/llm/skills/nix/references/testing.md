# Testing and Debugging Nix

## Checking Configurations

### Flake Checks
```bash
# Validate flake structure
nix flake check

# Build without switching (test build)
sudo nixos-rebuild build --flake .#hostname
darwin-rebuild build --flake .#hostname
home-manager build --flake .#user@hostname

# Dry run (show what would be built)
sudo nixos-rebuild dry-build --flake .#hostname

# Show trace on errors
sudo nixos-rebuild switch --flake .#hostname --show-trace
```

### Verbose Output
```bash
# Add verbosity levels
sudo nixos-rebuild switch --flake .#hostname -v    # Verbose
sudo nixos-rebuild switch --flake .#hostname -vvv  # Very verbose

# Print build logs
sudo nixos-rebuild switch --flake .#hostname --print-build-logs
# or shorthand
sudo nixos-rebuild switch --flake .#hostname -L

# Combined
sudo nixos-rebuild switch --flake .#hostname --show-trace -L -v
```

## Using the REPL

```bash
# Start REPL with nixpkgs
nix repl '<nixpkgs>'

# Start REPL with your flake
nix repl
nix-repl> :lf .

# Load flake explicitly
nix repl --expr 'import <nixpkgs> {}'
```

### REPL Commands
```
:?              # Help
:l <path>       # Load Nix expression
:lf <ref>       # Load flake
:r              # Reload files
:e <expr>       # Open in $EDITOR
:p <expr>       # Print recursively
:t <expr>       # Show type
:b <expr>       # Build derivation
:log <expr>     # Show build logs
:doc <builtin>  # Show builtin documentation
:q              # Quit
```

### Exploring Configurations
```bash
nix repl
nix-repl> :lf .

# Browse outputs
nix-repl> outputs.<TAB>
nix-repl> outputs.nixosConfigurations.<TAB>

# Inspect configuration
nix-repl> outputs.nixosConfigurations.hostname.config.services.<TAB>
nix-repl> outputs.nixosConfigurations.hostname.config.services.nginx.enable
true

# Check option definition
nix-repl> outputs.nixosConfigurations.hostname.options.services.nginx.enable
```

## Testing NixOS in VMs

### Build a VM
```bash
# Build VM image
nixos-rebuild build-vm --flake .#hostname

# Run the VM
./result/bin/run-*-vm

# With port forwarding
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-*-vm
```

### NixOS Tests
```nix
# In flake.nix
{
  checks.x86_64-linux.integration = nixpkgs.lib.nixos.runTest {
    name = "my-service-test";
    
    nodes.machine = { pkgs, ... }: {
      services.nginx.enable = true;
    };
    
    testScript = ''
      machine.wait_for_unit("nginx.service")
      machine.succeed("curl -s http://localhost")
    '';
  };
}
```

```bash
# Run tests
nix flake check
# or
nix build .#checks.x86_64-linux.integration
```

### Interactive VM Testing
```bash
# Run test interactively
nix run .#checks.x86_64-linux.integration.driverInteractive

# In Python console
>>> start_all()
>>> machine.shell_interact()  # Drop to shell
>>> machine.screenshot("test.png")
```

## Debugging Derivations

### Inspect Derivation
```bash
# Show derivation file
nix show-derivation nixpkgs#hello

# Get .drv path
nix path-info --derivation nixpkgs#hello
```

### Build with Debug
```bash
# Keep build directory on failure
nix build nixpkgs#hello --keep-failed

# Build in sandbox but keep env on failure
nix develop --ignore-environment nixpkgs#hello

# Build without sandbox (for debugging)
nix build --option sandbox false nixpkgs#hello
```

### Step Through Build Phases
```bash
# Enter build environment
nix develop nixpkgs#hello

# Manually run phases
unpackPhase
cd $sourceRoot
patchPhase
configurePhase
buildPhase
checkPhase
installPhase
```

## Common Debugging Scenarios

### "file not found" in Flakes
```bash
# Make sure files are tracked by git
git status
git add .
```

### Infinite Recursion
```bash
# Use --show-trace to find the cycle
nix build --show-trace

# Simplify config to isolate issue
```

### "cannot coerce to string"
Usually trying to use a derivation where a string is expected:
```nix
# Wrong
environment.variables.MY_PATH = pkgs.hello;

# Right
environment.variables.MY_PATH = "${pkgs.hello}";
# or
environment.variables.MY_PATH = pkgs.lib.getExe pkgs.hello;
```

### Module Conflicts
```bash
# See which modules define an option
nix repl
nix-repl> :lf .
nix-repl> outputs.nixosConfigurations.host.options.services.myService.enable.definitionsWithLocations
```

### Attribute Not Found
```nix
# Use lib.attrByPath with default
lib.attrByPath ["foo" "bar"] "default" mySet

# Or optional access
mySet.foo.bar or "default"
```

## nix-darwin Tests

```bash
# Run built-in tests
nix-build release.nix -A tests
nix-build release.nix -A tests.environment-path
```

## Home Manager Tests

```bash
# Dry run
home-manager build --flake .#user@host

# Show what would change
home-manager switch --flake .#user@host --dry-run
```

## Evaluating Expressions

```bash
# Evaluate and print
nix eval --expr '1 + 1'
nix eval nixpkgs#hello.meta.description

# Evaluate to JSON
nix eval --json nixpkgs#hello.meta

# Evaluate file
nix eval --file ./my-expression.nix
```

## Profiling Builds

```bash
# Show what will be built
nix build nixpkgs#hello --dry-run

# Build with timing
nix build nixpkgs#hello --print-build-logs 2>&1 | ts

# Check closure size
nix path-info -Sh nixpkgs#hello
```

## Store Inspection

```bash
# Query store path info
nix-store -q --references /nix/store/...
nix-store -q --referrers /nix/store/...
nix-store -q --tree /nix/store/...

# Why is something in store?
nix why-depends /run/current-system nixpkgs#openssl_1_1
```
