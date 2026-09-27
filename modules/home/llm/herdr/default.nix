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
        --prefix PATH : ${lib.makeBinPath [inputs.herdr.packages.${system}.default pkgs.git]}
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
      inputs.herdr.packages.${system}.default
      herdrWorkflows
      agentQuality
      pkgs.python3
    ];

    home.file =
      {
        ".hwf/workflows" = {
          source = ./workflows;
          recursive = true;
        };
        ".config/herdr/plugins/config/herdr-workflows/config.yaml".source = workflowsConfig;
        ".config/herdr/plugins/config/herdr-routines/routines.toml".source = ./routines.toml;
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
        herdr_bin=${inputs.herdr.packages.${system}.default}/bin/herdr

        $DRY_RUN_CMD "$herdr_bin" plugin link ${herdrWorkflows}
        $DRY_RUN_CMD "$herdr_bin" plugin link ${herdrRoutines}

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
