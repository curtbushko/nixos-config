{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types mkDefault concatStringsSep;
  cfg = config.curtbushko.llm.server;
  llmCfg = config.curtbushko.llm;

  # Build server command arguments
  serverArgs = concatStringsSep " " ([
    "--host 0.0.0.0"
    "--port ${toString cfg.port}"
    "--parallel ${toString cfg.slots}"
  ] ++ cfg.extraArgs
  ++ lib.optional (cfg.defaultModel != null) "-m ${cfg.defaultModel}");

in {
  options.curtbushko.llm.server = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable systemd socket-activated llama-cpp server with model slots.

        Features:
        - Socket activation: server starts on-demand when requests arrive
        - Model slots: load/switch models dynamically via API
        - Idle timeout: stops after inactivity to save resources
        - OpenAI-compatible API endpoints
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = ''
        Port for the llama-cpp server to listen on.
        Default: 8080 (http://localhost:8080)
      '';
    };

    slots = mkOption {
      type = types.int;
      default = 2;
      description = ''
        Number of model slots available.

        Allows:
        - Loading multiple models simultaneously
        - Switching models without restarting the server
        - Queuing requests across different models
      '';
    };

    defaultModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${config.curtbushko.llm.models.qwen.modelPath}";
      description = ''
        Default model to load on server startup.

        Set to null to start with no model loaded (load via API).
        Set to a model path to auto-load on startup.

        Example: config.curtbushko.llm.models.qwen.modelPath
      '';
    };

    idleTimeout = mkOption {
      type = types.str;
      default = "5min";
      description = ''
        How long to keep the server running after the last request.

        Examples: "30s", "5min", "10min", "1h"
        Set to "infinity" to keep running indefinitely.

        The server will automatically restart when a new request arrives
        thanks to socket activation.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["--ctx-size 4096" "--n-gpu-layers 35" "--threads 8"];
      description = ''
        Additional arguments to pass to llama-cpp-server.

        Common options:
          --ctx-size N          Context size (default: 512)
          --n-gpu-layers N      Layers to offload to GPU (-1 for all)
          --threads N           Number of threads to use
          --batch-size N        Batch size for prompt processing
          --rope-freq-base N    RoPE frequency base
          --rope-freq-scale N   RoPE frequency scale

        See: llama-cpp-server --help
      '';
    };
  };

  config = mkIf (llmCfg.enable && cfg.enable) {
    # Run llama-server as a normal service (not socket-activated)
    systemd.user.services.llama-server = {
      Unit = {
        Description = "llama.cpp server with model slots";
        Documentation = "https://github.com/ggerganov/llama.cpp";
        After = ["network.target"];
      };

      Service = {
        Type = "simple";
        # Use llama-server from system PATH (CUDA version from NixOS system packages)
        ExecStart = "/run/current-system/sw/bin/llama-server ${serverArgs}";
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

    # Helper scripts for managing the server
    programs.zsh.shellAliases = {
      llama-server-start = "systemctl --user start llama-server.service";
      llama-server-stop = "systemctl --user stop llama-server.service";
      llama-server-restart = "systemctl --user restart llama-server.service";
      llama-server-status = "systemctl --user status llama-server.service";
      llama-server-logs = "journalctl --user -u llama-server.service -f";
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
