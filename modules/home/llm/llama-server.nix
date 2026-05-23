{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types mkDefault concatStringsSep;
  cfg = config.curtbushko.llm.server;
  llmCfg = config.curtbushko.llm;

  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  # Linux: llama-cpp with CUDA
  # Build server command arguments for llama-cpp
  llamaServerArgs = concatStringsSep " " ([
    "--host 0.0.0.0"
    "--port ${toString cfg.port}"
    "--parallel ${toString cfg.slots}"
  ] ++ cfg.extraArgs
  ++ lib.optional (cfg.defaultModel != null) "-m ${cfg.defaultModel}");

  llamaServerBin = "/run/current-system/sw/bin/llama-server";

  # macOS: oMLX server (optimized MLX with tiered caching)
  # Installed via homebrew: brew tap jundot/omlx && brew install omlx
  omlxServerBin = "/opt/homebrew/bin/omlx";
  omlxModelDir = cfg.omlxModelDir;

in {
  options.curtbushko.llm.server = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable LLM server with OpenAI-compatible API.

        On Linux: Uses llama-cpp with CUDA/GPU acceleration
        On macOS: Uses MLX-LM (20-87% faster on Apple Silicon)

        Features:
        - OpenAI-compatible API endpoints
        - GPU acceleration (CUDA on Linux, Metal/MLX on macOS)
        - Background service with auto-restart
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = ''
        Port for the LLM server to listen on.
        Default: 8080 (http://localhost:8080)
      '';
    };

    slots = mkOption {
      type = types.int;
      default = 2;
      description = ''
        Number of model slots available (llama-cpp only).
      '';
    };

    defaultModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${config.curtbushko.llm.models.qwen.modelPath}";
      description = ''
        Default model path for llama-cpp (Linux).
        For GGUF model files.
      '';
    };

    omlxModelDir = mkOption {
      type = types.str;
      default = "~/models";
      description = ''
        Directory containing MLX models for oMLX (macOS).
        oMLX will serve all models in this directory.
        Download models via the oMLX admin UI or HuggingFace.
      '';
    };

    idleTimeout = mkOption {
      type = types.str;
      default = "5min";
      description = ''
        How long to keep the server running after the last request.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["--ctx-size 4096" "--n-gpu-layers 35" "--threads 8"];
      description = ''
        Additional arguments to pass to the server (llama-cpp on Linux).
      '';
    };
  };

  config = mkIf (llmCfg.enable && cfg.enable) {
    # Linux: Run llama-server as a systemd user service
    systemd.user.services = mkIf isLinux {
      llama-server = {
        Unit = {
          Description = "llama.cpp server with model slots";
          Documentation = "https://github.com/ggerganov/llama.cpp";
          After = ["network.target"];
        };

        Service = {
          Type = "simple";
          ExecStart = "${llamaServerBin} ${llamaServerArgs}";
          Restart = "on-failure";
          RestartSec = "10s";

          # Resource limits
          LimitNOFILE = 4096;

          # NVIDIA/CUDA device access
          DeviceAllow = [
            "/dev/dri"
            "/dev/nvidia0"
            "/dev/nvidiactl"
            "/dev/nvidia-modeset"
            "/dev/nvidia-uvm"
          ];

          # Security hardening (relaxed for GPU access)
          PrivateTmp = true;
          PrivateDevices = false;  # Must be false for GPU access
          NoNewPrivileges = true;
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    };

    # macOS: Run oMLX server as a launchd user agent
    launchd.agents = mkIf isDarwin {
      omlx-server = {
        enable = true;
        config = {
          Label = "com.omlx.server";
          ProgramArguments = [
            omlxServerBin
            "serve"
            "--model-dir" omlxModelDir
            "--port" (toString cfg.port)
          ];
          KeepAlive = true;
          RunAtLoad = false;  # Don't start automatically, start on demand
          StandardOutPath = "/tmp/omlx-server.log";
          StandardErrorPath = "/tmp/omlx-server.err";
          EnvironmentVariables = {
            PATH = "/opt/homebrew/bin:/run/current-system/sw/bin:/usr/bin:/bin";
          };
        };
      };
    };

    # Platform-specific helper aliases
    programs.zsh.shellAliases = if isLinux then {
      llm-server-start = "systemctl --user start llama-server.service";
      llm-server-stop = "systemctl --user stop llama-server.service";
      llm-server-restart = "systemctl --user restart llama-server.service";
      llm-server-status = "systemctl --user status llama-server.service";
      llm-server-logs = "journalctl --user -u llama-server.service -f";
    } else {
      # macOS: oMLX server via launchd (tiered caching, continuous batching)
      llm-server-start = "launchctl load ~/Library/LaunchAgents/com.omlx.server.plist 2>/dev/null || launchctl start com.omlx.server";
      llm-server-stop = "launchctl stop com.omlx.server";
      llm-server-restart = "launchctl stop com.omlx.server; sleep 1; launchctl start com.omlx.server";
      llm-server-status = "launchctl list | grep omlx || echo 'Not running'";
      llm-server-logs = "tail -f /tmp/omlx-server.log";
      # oMLX direct commands
      omlx-serve = "${omlxServerBin} serve --model-dir ${omlxModelDir}";
      omlx-admin = "open http://localhost:${toString cfg.port}/admin";
    };

    # API helper script for loading models
    home.file.".local/bin/llama-load-model" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        SERVER="http://127.0.0.1:${toString cfg.port}"

        usage() {
          cat << EOF
        Usage: llama-load-model <model-path> [slot-id]

        Load a model into llama-cpp server slot.

        Arguments:
          model-path    Path to the GGUF model file
          slot-id       Slot ID to load into (default: 0)

        Examples:
          # Load Qwen model into slot 0
          llama-load-model \$QWEN_MODEL_PATH

          # Load into specific slot
          llama-load-model /path/to/model.gguf 1

        Environment:
          QWEN_MODEL_PATH    Path to Qwen model (set by qwen.nix)

        Server API: ${toString cfg.port}
        EOF
        }

        if [ $# -lt 1 ]; then
          usage
          exit 1
        fi

        MODEL_PATH="$1"
        SLOT_ID="''${2:-0}"

        if [ ! -f "$MODEL_PATH" ]; then
          echo "Error: Model file not found: $MODEL_PATH"
          exit 1
        fi

        echo "Loading model into slot $SLOT_ID..."
        echo "  Model: $MODEL_PATH"
        echo "  Server: $SERVER"

        # Trigger socket activation if server not running
        curl -s "$SERVER/health" > /dev/null 2>&1 || sleep 1

        # Load model via API
        response=$(curl -s -X POST "$SERVER/slots/$SLOT_ID" \
          -H "Content-Type: application/json" \
          -d "{\"model\": \"$MODEL_PATH\"}")

        if echo "$response" | grep -q '"error"'; then
          echo "Error loading model:"
          echo "$response" | ${pkgs.jq}/bin/jq .
          exit 1
        else
          echo "✓ Model loaded successfully!"
          echo "$response" | ${pkgs.jq}/bin/jq .
        fi
      '';
      executable = true;
    };

    # Environment variables
    programs.zsh.sessionVariables = {
      LLAMA_SERVER_URL = "http://127.0.0.1:${toString cfg.port}";
    };
  };
}
