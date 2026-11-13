# Run with nix eval --impure --json --file modules/home/tools/tests/optional-tools.nix
let
  root = ../../../..;
  flake = builtins.getFlake (toString root);
  lib = flake.inputs.nixpkgs.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  tools = {config, ...}:
    builtins.removeAttrs (import ../default.nix {
      inherit config lib pkgs;
      inputs = flake.inputs;
    }) ["imports"];
  evaluate = settings:
    (lib.evalModules {
      modules = [
        tools
        {
          options.home.packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
          };
          options.programs.worktrunk.package = lib.mkOption {type = lib.types.package;};
          config.ns.tools = settings;
        }
      ];
    }).config;
  deck = import (root + "/homes/x86_64-linux/deck@steamdeck/default.nix") {
    inherit lib pkgs;
    inputs = flake.inputs;
  };
  defaults = evaluate {enable = true;};
  disabled = evaluate deck.ns.tools;
  off = evaluate {enable = false;};
  onlyYtDlp = evaluate {
    enable = true;
    sshuttle.enable = false;
  };
  onlySshuttle = evaluate {
    enable = true;
    yt-dlp.enable = false;
  };
  names = c: map (p: p.pname or p.name) c.home.packages;
  additionalTools = {
    nil = "nil";
    lima = "lima";
    remmina = "remmina";
    zathura = "zathura-with-plugins";
  };
  additionalChecks = lib.all (tool: let
    packageName = additionalTools.${tool};
    individuallyDisabled = evaluate {
      enable = true;
      ${tool}.enable = false;
    };
  in
    defaults.ns.tools.${tool}.enable
    && !disabled.ns.tools.${tool}.enable
    && builtins.elem packageName (names defaults)
    && !(builtins.elem packageName (names disabled))
    && !(builtins.elem packageName (names individuallyDisabled))
    && builtins.elem "sshuttle" (names individuallyDisabled)) (builtins.attrNames additionalTools);
in
  assert additionalChecks;
  assert defaults.ns.tools.yt-dlp.enable;
  assert defaults.ns.tools.sshuttle.enable;
  assert !disabled.ns.tools.yt-dlp.enable;
  assert !disabled.ns.tools.sshuttle.enable;
  assert builtins.elem "sshuttle" (names defaults);
  assert builtins.elem "yt-dlp" (names defaults);
  assert !(builtins.elem "sshuttle" (names disabled));
  assert !(builtins.elem "yt-dlp" (names disabled));
  assert builtins.elem "ripgrep" (names disabled);
  assert builtins.elem "yt-dlp" (names onlyYtDlp);
  assert !(builtins.elem "sshuttle" (names onlyYtDlp));
  assert builtins.elem "sshuttle" (names onlySshuttle);
  assert !(builtins.elem "yt-dlp" (names onlySshuttle));
  assert off.home.packages == []; true
