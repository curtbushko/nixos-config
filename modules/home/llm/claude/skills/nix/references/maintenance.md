# Nix Maintenance and Garbage Collection

## Updating Inputs

### Flake Updates
```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs
nix flake update home-manager

# Show current versions
nix flake metadata

# Show input lock info
cat flake.lock | jq
```

### After Updates
```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#hostname

# Or test first
sudo nixos-rebuild build --flake .#hostname
```

## Garbage Collection

### Basic Cleanup
```bash
# Collect garbage (remove unreferenced packages)
nix-collect-garbage

# Also delete old generations
nix-collect-garbage -d

# Delete generations older than N days
nix-collect-garbage --delete-older-than 7d
sudo nix-collect-garbage --delete-older-than 7d
```

### NixOS System Generations
```bash
# List system generations
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

# Delete old system generations (keeps current)
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old

# Delete generations older than 7 days
sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system

# Then garbage collect
sudo nix-collect-garbage
```

### Home Manager Generations
```bash
# List home-manager generations
home-manager generations

# Remove old generations
home-manager expire-generations -7d

# Then garbage collect
nix-collect-garbage
```

### nix-darwin Generations
```bash
# List darwin generations
darwin-rebuild --list-generations

# Delete old generations
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old

# Garbage collect
nix-collect-garbage -d
```

## Automatic Garbage Collection

### NixOS Configuration
```nix
{
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Limit boot loader entries
  boot.loader.systemd-boot.configurationLimit = 10;
  # or for GRUB
  boot.loader.grub.configurationLimit = 10;
}
```

### nix-darwin Configuration
```nix
{
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 2; Minute = 0; };  # Sunday 2 AM
    options = "--delete-older-than 30d";
  };
}
```

### Automatic GC on Low Space
```nix
{
  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';
}
```
This triggers GC when free space drops below 100MB, freeing up to 1GB.

## Store Optimization

### Deduplication (Hard Links)
```bash
# Run optimization manually
nix-store --optimise

# Show store size
du -sh /nix/store

# Show with dedup stats
nix-store --gc --print-dead
```

### Auto-optimization
```nix
{
  nix.settings.auto-optimise-store = true;
}
```

## GC Roots

GC roots prevent packages from being collected.

### List GC Roots
```bash
nix-store --gc --print-roots

# Filter out runtime roots
nix-store --gc --print-roots | grep -v '/proc/'
```

### Common GC Root Locations
- `/nix/var/nix/profiles/` - System and user profiles
- `/nix/var/nix/gcroots/` - Explicit GC roots
- `./result` - Build result symlinks

### Remove Stale Roots
```bash
# Remove result symlinks (careful!)
find /nix/var/nix/gcroots/auto -type l ! -exec test -e {} \; -delete

# Remove project result links
rm ./result
```

## Protecting Packages

### Keep Specific Packages
```bash
# Create GC root
nix-store --add-root /nix/var/nix/gcroots/my-package --indirect -r $(nix-build '<nixpkgs>' -A hello)

# Or for flakes
nix build --out-link /nix/var/nix/gcroots/my-package nixpkgs#hello
```

### Protect Development Shells
```bash
# Create profile that survives GC
nix develop --profile ./.nix-profile
```

## Rollback

### System Rollback
```bash
# Boot into previous generation via boot menu (GRUB/systemd-boot)

# Or switch from running system
sudo nixos-rebuild switch --rollback

# Or to specific generation
sudo nixos-rebuild switch --flake .#hostname
# (after git checkout to previous commit)
```

### Home Manager Rollback
```bash
# List generations
home-manager generations

# Activate previous
/nix/var/nix/profiles/per-user/$USER/home-manager-N-link/activate
```

## Disk Usage Analysis

```bash
# Store size
du -sh /nix/store

# Largest packages
du -sh /nix/store/* | sort -h | tail -20

# Closure size of a package
nix path-info -Sh nixpkgs#firefox

# What's keeping something in store?
nix why-depends /run/current-system /nix/store/...-openssl-1.1.1
```

## Maintenance Checklist

Weekly:
- [ ] `nix flake update` (in your config repo)
- [ ] Test build before switching
- [ ] `sudo nixos-rebuild switch`

Monthly:
- [ ] `sudo nix-collect-garbage --delete-older-than 30d`
- [ ] `nix-store --optimise`
- [ ] Check disk usage

As Needed:
- [ ] Clean old boot entries (limit via configurationLimit)
- [ ] Remove unused GC roots
- [ ] Remove stale result symlinks

## Best Practices

1. **Keep recent generations** - Don't delete all old generations immediately after switching
2. **Test before switching** - Use `nixos-rebuild build` first
3. **Commit flake.lock** - Pin your dependencies in version control
4. **Set configuration limits** - Prevent boot menu overflow
5. **Regular maintenance** - Set up automatic GC
6. **Monitor disk space** - `/nix/store` can grow large
