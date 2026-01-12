# nix-darwin Best Practices

nix-darwin brings NixOS-style declarative configuration to macOS.

## Installation

### Using Determinate Systems Installer (Recommended)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Initialize nix-darwin
```bash
# Create config directory
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

# Initialize flake
nix flake init -t nix-darwin/master

# Update hostname in flake.nix
sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix

# First build
nix run nix-darwin -- switch --flake .
```

## Basic Flake Structure

```nix
{
  description = "Darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager, ... }@inputs: {
    darwinConfigurations."hostname" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";  # or x86_64-darwin for Intel
      specialArgs = { inherit inputs; };
      modules = [
        ./darwin-configuration.nix
        home-manager.darwinModules.home-manager
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

## darwin-configuration.nix

```nix
{ config, pkgs, ... }:

{
  # Required
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@admin" ];
  };

  # System packages (available to all users)
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Enable Touch ID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
  ];

  # System defaults
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      minimize-to-application = true;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.swipescrolldirection" = false;  # Natural scrolling off
    };
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };

  # Keyboard settings
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  # Shell
  programs.zsh.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 4;
}
```

## Homebrew Integration

nix-darwin can manage Homebrew packages declaratively:

```nix
{
  homebrew = {
    enable = true;
    
    # Uninstall packages not in config
    onActivation = {
      autoUpdate = false;  # Don't auto-update on rebuild
      cleanup = "zap";     # Remove unlisted packages
      upgrade = false;     # Don't auto-upgrade
    };

    # Taps
    taps = [
      "homebrew/services"
    ];

    # CLI tools (prefer nixpkgs when available)
    brews = [
      "mas"  # Mac App Store CLI
    ];

    # GUI applications
    casks = [
      "1password"
      "alfred"
      "docker"
      "firefox"
      "iterm2"
      "raycast"
      "slack"
      "visual-studio-code"
    ];

    # Mac App Store apps (requires mas)
    masApps = {
      "Xcode" = 497799835;
      "Keynote" = 409183694;
    };
  };
}
```

## Services

```nix
{
  # Nix daemon
  services.nix-daemon.enable = true;

  # Yabai (tiling window manager)
  services.yabai = {
    enable = true;
    config = {
      layout = "bsp";
      window_gap = 10;
    };
  };

  # skhd (hotkey daemon)
  services.skhd = {
    enable = true;
    skhdConfig = ''
      alt - return : open -a iTerm
      alt - h : yabai -m window --focus west
    '';
  };

  # Aerospace (alternative tiling WM)
  services.aerospace = {
    enable = true;
    settings = {
      gaps = {
        inner.horizontal = 10;
        inner.vertical = 10;
      };
    };
  };
}
```

## Multiple Macs

```nix
{
  outputs = { self, nix-darwin, ... }@inputs:
    let
      commonModules = [
        ./common.nix
        home-manager.darwinModules.home-manager
      ];
    in {
      darwinConfigurations = {
        "work-mbp" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = commonModules ++ [ ./hosts/work-mbp.nix ];
        };
        "personal-mbp" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = commonModules ++ [ ./hosts/personal-mbp.nix ];
        };
        "old-intel-mac" = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = commonModules ++ [ ./hosts/intel-mac.nix ];
        };
      };
    };
}
```

## Essential Commands

```bash
# Build and switch
darwin-rebuild switch --flake .#hostname

# Build without switching (test)
darwin-rebuild build --flake .#hostname

# Show available options
darwin-rebuild --help

# Check config
darwin-rebuild check --flake .

# Rollback to previous generation
darwin-rebuild switch --rollback
```

## Differences from NixOS

| Feature | NixOS | nix-darwin |
|---------|-------|------------|
| Boot loader | Yes | No |
| Kernel modules | Yes | No |
| systemd services | Yes | No (uses launchd) |
| User creation | Full control | Limited (use `users.users`) |
| Homebrew | No | Yes (optional) |

## Tips

### Prefer nixpkgs over Homebrew
Use nixpkgs packages when available—they're more reproducible:
```nix
environment.systemPackages = with pkgs; [ git vim ];  # Good
homebrew.brews = [ "git" "vim" ];  # Avoid if nixpkgs has it
```

### Use Homebrew Casks for GUI Apps
Many macOS GUI apps aren't in nixpkgs or have issues:
```nix
homebrew.casks = [ "firefox" "slack" ];  # Works better for GUI apps
```

### Path Setup
nix-darwin configures PATH automatically, but ensure Nix paths come first:
```nix
environment.systemPath = [ "/opt/homebrew/bin" ];  # After Nix paths
```

## Finding Options

- [nix-darwin Options](https://nix-darwin.github.io/nix-darwin/manual/)
- [nix-darwin Source](https://github.com/LnL7/nix-darwin/tree/master/modules)
