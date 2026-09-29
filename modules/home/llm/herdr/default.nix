{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.llm;
  herdrPackage = inputs.herdr-nixpkgs.legacyPackages.${system}.herdr;

  workflowRelease = {
    x86_64-linux = {
      asset = "herdr-workflows_0.15.1_linux_amd64.tar.gz";
      hash = "sha256-ObjbNHDt2OWGKUr0WozN+W0DxRXGzOyFg7TuchZyEeY=";
    };
    aarch64-linux = {
      asset = "herdr-workflows_0.15.1_linux_arm64.tar.gz";
      hash = "sha256-8nn/IpG8wvL9jJb3Pwhjc+2JY4b3uzRVKfhlVmwqFw8=";
    };
    x86_64-darwin = {
      asset = "herdr-workflows_0.15.1_darwin_amd64.tar.gz";
      hash = "sha256-8uTEcIqD8Kn5IkZ+Ygy5Q1hF1qI8n2hE65aBLTDKLpM=";
    };
    aarch64-darwin = {
      asset = "herdr-workflows_0.15.1_darwin_arm64.tar.gz";
      hash = "sha256-gkJI8XmEf49xvGF5B6s59aSRHxN3GipWUlErUdSQ9Kk=";
    };
  };
  workflowPlatform = workflowRelease.${system};
  workflowArchive = pkgs.fetchurl {
    url = "https://github.com/aorumbayev/herdr-workflows/releases/download/v0.15.1/${workflowPlatform.asset}";
    inherit (workflowPlatform) hash;
  };
  herdrWorkflows = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-workflows-plugin";
    version = "0.15.1";
    src = inputs.herdr-workflows;
    nativeBuildInputs = [pkgs.makeWrapper];
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      cp -R . "$out/"
      tar -xzf ${workflowArchive} -C "$out/bin"
      chmod +x "$out/bin/herdr-workflows"
      wrapProgram "$out/bin/herdr-workflows" \
        --prefix PATH : ${lib.makeBinPath [herdrPackage pkgs.git]}
      runHook postInstall
    '';
  };
  herdrRoutines = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-routines-plugin";
    version = "0.1.0-cd504512";
    src = inputs.herdr-routines;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R . "$out/"
      substituteInPlace "$out/herdr-plugin.toml" \
        --replace-fail 'python3 ' '${pkgs.python3}/bin/python3 '
      runHook postInstall
    '';
  };
  agentQuality = pkgs.writeShellApplication {
    name = "agent-quality";
    runtimeInputs = [pkgs.git pkgs.go-task];
    text = builtins.readFile ./agent-quality.sh;
  };
  herdrSmartFocus = pkgs.writeShellApplication {
    name = "herdr-smart-focus";
    runtimeInputs = [herdrPackage pkgs.jq];
    text = builtins.readFile ../../scripts/herdr-smart-focus;
  };

  whichkeyVendorHash = "sha256-ykx/GZcbWmir8TaDELIo2rm8DbEll6ccQDT9jhknZog=";
  whichkeyUnwrapped = pkgs.buildGoModule {
    pname = "herdr-whichkey";
    version = "0.1.0";
    src = ./whichkey;
    vendorHash = whichkeyVendorHash;
    doCheck = false;
  };
  whichkeyBin = pkgs.symlinkJoin {
    name = "herdr-whichkey-wrapped";
    paths = [whichkeyUnwrapped];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/whichkey \
        --set HERDR_BIN_PATH ${herdrPackage}/bin/herdr
    '';
  };
  whichkeyPlugin = pkgs.runCommand "herdr-whichkey-plugin" {} ''
    mkdir -p "$out"
    ${pkgs.gnused}/bin/sed \
      -e "s|@WHICHKEY_BIN@|${whichkeyBin}/bin/whichkey|g" \
      ${./whichkey/herdr-plugin.toml.in} > "$out/herdr-plugin.toml"
  '';

  herdrNvim = pkgs.rustPlatform.buildRustPackage {
    pname = "herdr-nvim";
    version = "1.1.0";
    src = inputs.herdr-nvim;
    cargoHash = "sha256-pImtQ1YiM47VvA8u9ER/lXtDVsZhQy38fkCbzmT/gc4=";
    doCheck = false;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      install -m 0755 target/${pkgs.stdenv.hostPlatform.rust.cargoShortTarget}/release/herdr-nvim "$out/bin/herdr-nvim"
      cp herdr-plugin.toml "$out/herdr-plugin.toml"
      cp -R doc lua plugin "$out/"
      runHook postInstall
    '';
  };
  herdrNvimConfig = pkgs.writeText "herdr-nvim-config.toml" ''
    [sidebar]
    nvim_bin = "${inputs.neovim.packages.${system}.default}/bin/nvim"
  '';

  flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";
  defaultFlairColors = {
    "accent-primary" = "#7fbbb3";
    "surface-bg" = "#2d353b";
    "surface-bg-sidebar" = "#2d353b";
    "surface-bg-raised" = "#232a2e";
    "surface-bg-highlight" = "#343f44";
    "surface-bg-selection" = "#465d5f";
    "surface-bg-darkest" = "#232a2e";
    "border-focus" = "#66938f";
    "text-primary" = "#d3c6aa";
    "text-secondary" = "#9da9a0";
    "text-muted" = "#859289";
    "text-subtle" = "#596462";
    "terminal-green" = "#a7c080";
    "terminal-yellow" = "#dbbc7f";
    "terminal-red" = "#e67e80";
    "terminal-blue" = "#7fbbb3";
    "terminal-cyan" = "#83c092";
    "terminal-magenta" = "#d0a4de";
    "syntax-constant" = "#e69875";
  };
  flairColors =
    if builtins.pathExists flairStylePath
    then builtins.fromJSON (builtins.readFile flairStylePath)
    else defaultFlairColors;
  herdrConfig = pkgs.writeText "herdr-config.toml" ''
    onboarding = false

    [ui.sound]
    enabled = false

    [theme]
    name = "terminal"

    [theme.custom]
    accent = "${flairColors."accent-primary"}"
    panel_bg = "${flairColors."surface-bg"}"
    sidebar_bg = "reset"
    active_row_bg = "${flairColors."surface-bg-highlight"}"
    selection_bg = "${flairColors."surface-bg-selection"}"
    surface0 = "${flairColors."surface-bg-raised"}"
    surface1 = "${flairColors."surface-bg-highlight"}"
    surface_dim = "${flairColors."border-focus"}"
    overlay0 = "${flairColors."text-subtle"}"
    overlay1 = "${flairColors."text-muted"}"
    text = "${flairColors."text-primary"}"
    subtext0 = "${flairColors."text-secondary"}"
    mauve = "${flairColors."terminal-magenta"}"
    green = "${flairColors."terminal-green"}"
    yellow = "${flairColors."terminal-yellow"}"
    red = "${flairColors."terminal-red"}"
    blue = "${flairColors."terminal-blue"}"
    teal = "${flairColors."terminal-cyan"}"
    peach = "${flairColors."syntax-constant"}"

    [keys]
    prefix = "ctrl+b"

    detach = "prefix+d"

    # Splits (tmux: M-n split right, M-m split down)
    split_vertical = ["prefix+v", "alt+n"]
    split_horizontal = ["prefix+minus", "alt+m"]

    # Pane focus (tmux: M-h/j/k/l and M-arrows)
    focus_pane_left = ["prefix+h", "alt+left"]
    focus_pane_down = ["prefix+j", "alt+j", "alt+down"]
    focus_pane_up = ["prefix+k", "alt+k", "alt+up"]
    focus_pane_right = ["prefix+l", "alt+right"]

    # Tab navigation (ctrl+tab/ctrl+shift+tab do not survive ssh; use alt bracket)
    previous_tab = "alt+["
    next_tab = "alt+]"

    # Pane resize (tmux: M-= grow up, M-- shrink down)
    resize_pane_up = "alt+="
    resize_pane_down = "alt+-"

    # Zoom pane (tmux: M-p)
    zoom = ["prefix+z", "alt+p"]

    # Tab switching (tmux: M-1..9)
    switch_tab = ["prefix+1..9", "alt+1..9"]

    [[keys.command]]
    key = "alt+h"
    type = "shell"
    command = "${herdrSmartFocus}/bin/herdr-smart-focus left"
    description = "focus left pane or previous tab"

    [[keys.command]]
    key = "alt+l"
    type = "shell"
    command = "${herdrSmartFocus}/bin/herdr-smart-focus right"
    description = "focus right pane or next tab"

    [[keys.command]]
    key = "prefix+space"
    type = "popup"
    command = "${whichkeyBin}/bin/whichkey"
    description = "which-key menu"
    width = "50%"
    height = 16

    [[keys.command]]
    key = "alt+space"
    type = "popup"
    command = "${whichkeyBin}/bin/whichkey"
    description = "which-key menu"
    width = "50%"
    height = 16

    [[keys.command]]
    key = "prefix+e"
    type = "plugin_action"
    command = "chmarax.herdr-nvim.toggle"
    description = "nvim sidebar"

    [[keys.command]]
    key = "prefix+o"
    type = "plugin_action"
    command = "chmarax.herdr-nvim.pick-file"
    description = "open file from agent output"

  '';

  herdrIntegrations = ["pi" "claude" "codex"] ++ lib.optionals cfg.copilot.enable ["copilot"];
  copilotWorkflowProfile = "  copilot:\n    kind: copilot\n";
  workflowsConfig = pkgs.writeText "herdr-workflows-config.yaml" (
    builtins.replaceStrings
    [copilotWorkflowProfile]
    [(lib.optionalString cfg.copilot.enable copilotWorkflowProfile)]
    (builtins.readFile ./workflows-config.yaml)
  );
in {
  config = mkIf cfg.enable {
    home.packages = [
      herdrPackage
      (pkgs.runCommand "herdr-workflows-bin" {} ''
        mkdir -p $out
        cp -R ${herdrWorkflows}/bin $out/bin
      '')
      (pkgs.runCommand "herdr-nvim-bin" {} ''
        mkdir -p $out
        cp -R ${herdrNvim}/bin $out/bin
      '')
      agentQuality
      pkgs.python3
    ];

    home.file =
      {
        ".hwf/workflows" = {
          source = ./workflows;
          recursive = true;
        };
        ".config/herdr/config.toml".source = herdrConfig;
        ".config/herdr-nvim/config.toml".source = herdrNvimConfig;
        ".config/herdr/plugins/config/herdr-workflows/config.yaml".source = workflowsConfig;
        ".config/herdr/plugins/config/herdr-routines/routines.toml".source = ./routines.toml;
        ".config/herdr/plugins/config/whichkey/menu.toml".source = ./whichkey/menu.toml;
        ".codex/hooks.json".source = pkgs.writeText "herdr-codex-hooks.json" (builtins.toJSON {
          hooks.SessionStart = [
            {
              hooks = [
                {
                  type = "command";
                  command = "bash '${config.home.homeDirectory}/.codex/herdr-agent-state.sh' session";
                  timeout = 10;
                }
              ];
            }
          ];
        });
      }
      // lib.optionalAttrs cfg.copilot.enable {
        ".copilot/settings.json".text = builtins.toJSON {
          hooks.SessionStart = [
            {
              type = "command";
              bash = "bash '${config.home.homeDirectory}/.copilot/hooks/herdr-agent-state.sh'";
              timeoutSec = 10;
            }
          ];
        };
      };

    home.activation.configureHerdr =
      config.lib.dag.entryAfter ["writeBoundary"]
      ''
        herdr_bin=${herdrPackage}/bin/herdr

        $DRY_RUN_CMD "$herdr_bin" plugin link ${herdrWorkflows}
        $DRY_RUN_CMD "$herdr_bin" plugin link ${herdrRoutines}
        $DRY_RUN_CMD "$herdr_bin" plugin link ${whichkeyPlugin}
        if "$herdr_bin" plugin list | ${pkgs.gnugrep}/bin/grep -q '^- herdr-context '; then
          $DRY_RUN_CMD "$herdr_bin" plugin unlink herdr-context
        fi
        $DRY_RUN_CMD "$herdr_bin" plugin link ${herdrNvim}
        if "$herdr_bin" plugin list | ${pkgs.gnugrep}/bin/grep -q '^- herdr.auto-title '; then
          $DRY_RUN_CMD "$herdr_bin" plugin unlink herdr.auto-title
        fi
        if "$herdr_bin" plugin list | ${pkgs.gnugrep}/bin/grep -q '^- blurname.git-tab-name '; then
          $DRY_RUN_CMD "$herdr_bin" plugin unlink blurname.git-tab-name
        fi

        integration_home="$(${pkgs.coreutils}/bin/mktemp -d)"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
          "$integration_home/.pi/agent/extensions" \
          "$integration_home/.claude" \
          "$integration_home/.codex"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '{}\n' > "$integration_home/.claude/settings.json"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '\n' > "$integration_home/.codex/config.toml"
        ${lib.optionalString cfg.copilot.enable ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$integration_home/.copilot"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '{}\n' > "$integration_home/.copilot/settings.json"
        ''}

        for integration in ${lib.concatStringsSep " " herdrIntegrations}; do
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/env -u CODEX_HOME \
            HOME="$integration_home" \
            XDG_CONFIG_HOME="$integration_home/.config" \
            "$herdr_bin" integration install "$integration"
        done

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
          "$HOME/.pi/agent/extensions" \
          "$HOME/.claude/hooks" \
          "$HOME/.codex"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 \
          "$integration_home/.pi/agent/extensions/herdr-agent-state.ts" \
          "$HOME/.pi/agent/extensions/herdr-agent-state.ts"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0755 \
          "$integration_home/.claude/hooks/herdr-agent-state.sh" \
          "$HOME/.claude/hooks/herdr-agent-state.sh"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0755 \
          "$integration_home/.codex/herdr-agent-state.sh" \
          "$HOME/.codex/herdr-agent-state.sh"
        ${lib.optionalString cfg.copilot.enable ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.copilot/hooks"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0755 \
            "$integration_home/.copilot/hooks/herdr-agent-state.sh" \
            "$HOME/.copilot/hooks/herdr-agent-state.sh"
        ''}
        ${lib.optionalString (!cfg.copilot.enable) ''
          if [ -f "$HOME/.copilot/hooks/herdr-agent-state.sh" ]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.trash/herdr-copilot"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv --backup=numbered \
              "$HOME/.copilot/hooks/herdr-agent-state.sh" \
              "$HOME/.trash/herdr-copilot/"
          fi
        ''}
      '';
  };
}
