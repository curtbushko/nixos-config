{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix/f4f8d6e7cc59e34e5a85550f017ead83ab925b22";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flair = {
      url = "github:curtbushko/flair";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    llmfit = {
      url = "github:AlexsJones/llmfit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:dan-online/opencode-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minecraft-servers = {
      url = "github:curtbushko/minecraft-servers";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim = {
      url = "github:curtbushko/neovim-flake";
      # Don't override nixpkgs - neovim-flake needs its own nixpkgs for nixvim compatibility
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    stevenblack-hosts = {
      url = "github:StevenBlack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      #  02/17/25 - home manager broke something with qt6 and theming. It interacted poorly with stylix
      # pin to this version of stylix
      #https://github.com/danth/stylix/issues/835
      #url = "github:danth/stylix?ref=b00c9f46ae6c27074d24d2db390f0ac5ebcc329f";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = inputs: let
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "curtbushko";
        meta = {
          name = "curtbushko";
          title = "Custom Flake";
        };
      };
    };

    # Generate devShells for all supported systems
    devShells =
      inputs.nixpkgs.lib.genAttrs
      ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"]
      (system: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        make-wrapper = pkgs.writeShellScriptBin "make" ''
          exec ${pkgs.go-task}/bin/task "$@"
        '';
      in {
        default = pkgs.mkShell {
          packages = with pkgs;
            [
              # Version control
              git

              # Nix formatting and linting
              alejandra
              nixpkgs-fmt
              nixd

              # YAML linting
              yamllint

              # Secrets management (sops-nix)
              sops
              age

              # Task runner
              go-task
              make-wrapper
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
              # Linux specific
              nixos-rebuild
            ];

          shellHook = ''
            # Auto-pull if on main branch
            if [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = "main" ]; then
              echo "On main branch, pulling latest changes..."
              git pull --quiet || true
            fi

            # Terminal colors
            BOLD='\033[1m'
            BLUE='\033[0;34m'
            GREEN='\033[0;32m'
            YELLOW='\033[0;33m'
            CYAN='\033[0;36m'
            MAGENTA='\033[0;35m'
            NC='\033[0m' # No Color

            echo -e "''${BOLD}''${BLUE}NixOS Configuration Development Environment''${NC}"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo -e "''${BOLD}Repository:''${NC} curtbushko/nixos-config"
            echo -e "''${BOLD}Current host:''${NC} $(hostname -s)"
            echo -e "''${BOLD}System:''${NC} $(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
            echo ""

            echo -e "''${BOLD}''${GREEN}Common Tasks:''${NC}"
            echo "  task switch     - Build and apply configuration (default)"
            echo "  task test       - Test configuration without switching"
            echo "  task fmt        - Format all Nix files with alejandra"
            echo "  task update-all - Update all flake inputs"
            echo "  task gc         - Garbage collect old generations (3+ days)"
            echo "  task -l         - List all available tasks"
            echo ""

            echo -e "''${BOLD}''${YELLOW}Repository Structure:''${NC}"
            echo "  flake.nix       - Main entry point with inputs/outputs"
            echo "  systems/        - Per-machine NixOS/Darwin configurations"
            echo "  modules/home/   - Cross-platform home-manager modules"
            echo "  modules/nixos/  - NixOS-specific modules"
            echo "  modules/darwin/ - macOS-specific modules"
            echo "  Taskfile.yml    - Task definitions (replaces Makefile)"
            echo ""

            echo -e "''${BOLD}''${CYAN}Available Tools:''${NC}"
            echo "  alejandra       - Nix code formatter (opinionated)"
            echo "  nixpkgs-fmt     - Nix code formatter (minimal)"
            echo "  nixd            - Nix language server"
            echo "  yamllint        - YAML linter"
            echo "  sops/age        - Secrets management"
            echo "  go-task         - Task runner (aliased as 'make')"
            echo ""

            echo -e "''${BOLD}''${MAGENTA}Quick Tips:''${NC}"
            echo "  • Config layers: flake.nix → systems → modules/[nixos|darwin] → modules/home"
            echo "  • Format before commit: task fmt"
            echo "  • Test changes safely: task test"
            echo "  • See README.md for architecture details"
            echo "  • Snowfall lib provides the directory structure"
            echo ""

            echo -e "''${BOLD}''${BLUE}Documentation:''${NC}"
            echo "  README.md                     - Repository overview and design"
            echo "  modules/home/llm/claude/      - Claude skills and agents"
            echo "  Taskfile.yml                  - All available tasks"
            echo ""
            echo -e "Run ''${BOLD}task''${NC} to build and switch your configuration"
            echo ""
          '';
        };
      });

    flakeOutputs = lib.mkFlake {
      # Add armv7l-linux to the default supported systems
      supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" "armv7l-linux"];

      channels-config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        allowBroken = true;
        permittedInsecurePackages = [
          # "python-2.7.18.6"
          "electron-25.9.0"
          "qtwebengine-5.15.19"
        ];
      };

      overlays = with inputs; [
        zig.overlays.default
      ];

      systems.modules.darwin = with inputs; [
        home-manager.darwinModules.home-manager
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        stevenblack-hosts.nixosModule
      ];
    };
  in
    flakeOutputs // {inherit devShells;};
}
