# Home-Manager Best Practices

## Installation Methods

### As NixOS Module (Recommended for NixOS)
```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.username = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
```

### Standalone (Non-NixOS or Independent Management)
```nix
# flake.nix
{
  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
      extraSpecialArgs = { inherit inputs; };
    };
  };
}
```

```bash
# Apply standalone config
home-manager switch --flake .#user@hostname
```

## Basic home.nix Structure

```nix
{ config, pkgs, lib, ... }:

{
  home.username = "username";
  home.homeDirectory = "/home/username";
  home.stateVersion = "24.11";  # Don't change after initial setup

  # Packages installed to user profile
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    htop
  ];

  # Dotfiles
  home.file = {
    ".config/starship.toml".source = ./starship.toml;
    ".local/bin/myscript" = {
      executable = true;
      text = ''
        #!/bin/bash
        echo "Hello"
      '';
    };
  };

  # XDG config files
  xdg.configFile = {
    "nvim/init.lua".source = ./nvim/init.lua;
    "i3/config".text = ''
      # i3 config content
    '';
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
  };

  # Shell aliases
  home.shellAliases = {
    ll = "ls -la";
    ".." = "cd ..";
  };

  # Enable home-manager itself
  programs.home-manager.enable = true;
}
```

## Program Modules

Home-manager has built-in support for many programs:

```nix
{
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your@email.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
    delta.enable = true;  # Better diff viewer
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" ];
      theme = "robbyrussell";
    };
    initExtra = ''
      # Custom zsh config
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      telescope-nvim
      nvim-treesitter
    ];
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character.success_symbol = "[➜](bold green)";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;  # Caches nix-shell environments
  };

  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.zoxide.enable = true;
}
```

## Services (Linux-only)

```nix
{
  services.syncthing.enable = true;
  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrains Mono 10";
        frame_width = 2;
      };
    };
  };
}
```

## Modular Configuration

Split config into modules:

```
homes/
├── modules/
│   ├── shell/
│   │   ├── default.nix  # Imports all shell modules
│   │   ├── zsh.nix
│   │   └── starship.nix
│   ├── editors/
│   │   ├── default.nix
│   │   └── neovim.nix
│   └── dev/
│       ├── default.nix
│       ├── git.nix
│       └── direnv.nix
└── username@hostname/
    └── default.nix  # Imports required modules
```

```nix
# homes/username@hostname/default.nix
{ ... }:
{
  imports = [
    ../modules/shell
    ../modules/editors
    ../modules/dev
  ];

  # Host-specific overrides
  custom.git.userEmail = "work@company.com";
}
```

## Custom Options Pattern

```nix
# modules/dev/git.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.git;
in {
  options.custom.git = {
    enable = lib.mkEnableOption "Git configuration";
    userName = lib.mkOption {
      type = lib.types.str;
      default = "Default Name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git email address";
    };
    signing = {
      enable = lib.mkEnableOption "GPG signing";
      key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
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
    };
  };
}
```

## Accessing NixOS Config

When home-manager is a NixOS module, access system config via `osConfig`:

```nix
{ config, osConfig, pkgs, ... }:
{
  programs.git.userEmail = 
    if osConfig.networking.hostName == "work-laptop"
    then "work@company.com"
    else "personal@email.com";
}
```

## Useful Settings

```nix
{
  # Share global pkgs (saves eval time)
  home-manager.useGlobalPkgs = true;
  
  # Install packages to /etc/profiles instead of ~/.nix-profile
  home-manager.useUserPackages = true;
  
  # Pass extra arguments to home.nix
  home-manager.extraSpecialArgs = { inherit inputs; };
  
  # Backup files that would be overwritten
  home-manager.backupFileExtension = "backup";
}
```

## Common Issues

### Missing session variables
Source the session file in your shell:
```bash
# In .bashrc or .zshrc
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
```

### Conflicts with existing dotfiles
Home-manager won't overwrite existing files by default. Either:
- Remove/backup existing files manually
- Set `home.file."path".force = true`
- Use `home-manager.backupFileExtension`

### State version warnings
Never change `home.stateVersion` after initial setup—it controls migration behavior.

## Finding Options

- [Home Manager Options Search](https://home-manager-options.extranix.com/)
- [Official Options Appendix](https://nix-community.github.io/home-manager/options.xhtml)
- Browse source: `nix repl` then `:lf github:nix-community/home-manager`
