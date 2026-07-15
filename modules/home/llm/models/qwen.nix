{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
  cfg = config.ns.llm.models.qwen;
  llmCfg = config.ns.llm;

  # Base directory for all llama.cpp models
  modelsBaseDir = "${config.home.homeDirectory}/.local/share/llama-cpp/models";

  # Qwen models subdirectory
  qwenModelsDir = "${modelsBaseDir}/qwen";

  # Specific model directory
  modelDir = "${qwenModelsDir}/${cfg.variant}";

  # HuggingFace repository mapping
  variantRepos = {
    # GGUF formats (for llama.cpp)
    "2.5-coder-7b-instruct-gguf" = "bartowski/Qwen2.5-Coder-7B-Instruct-GGUF";
    "2.5-coder-14b-instruct-gguf" = "bartowski/Qwen2.5-Coder-14B-Instruct-GGUF";
    "2.5-coder-32b-instruct-gguf" = "bartowski/Qwen2.5-Coder-32B-Instruct-GGUF";
    # GPTQ formats (safetensors - not for llama.cpp)
    "2.5-coder-7b-instruct-gptq-int4" = "Qwen/Qwen2.5-Coder-7B-Instruct-GPTQ-Int4";
    "2.5-coder-14b-instruct-gptq-int4" = "Qwen/Qwen2.5-Coder-14B-Instruct-GPTQ-Int4";
    "2.5-coder-32b-instruct-gptq-int4" = "Qwen/Qwen2.5-Coder-32B-Instruct-GPTQ-Int4";
  };

  hfRepo = variantRepos.${cfg.variant} or cfg.variant;
in {
  options.ns.llm.models.qwen = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Qwen model management for llama.cpp
      '';
    };

    variant = mkOption {
      type = types.str;
      default = "2.5-coder-7b-instruct-gguf";
      description = ''
        Which Qwen model variant to use.

        Available GGUF options (for llama.cpp):
          - 2.5-coder-7b-instruct-gguf (default)
          - 2.5-coder-14b-instruct-gguf
          - 2.5-coder-32b-instruct-gguf

        Available GPTQ options (safetensors - not for llama.cpp):
          - 2.5-coder-7b-instruct-gptq-int4
          - 2.5-coder-14b-instruct-gptq-int4
          - 2.5-coder-32b-instruct-gptq-int4

        Or specify a custom HuggingFace repository path.
      '';
    };

    modelFile = mkOption {
      type = types.str;
      default = "Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf";
      description = ''
        The GGUF model file name within the model directory.

        Common bartowski quantizations:
          - Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf (recommended, ~4.4GB)
          - Qwen2.5-Coder-7B-Instruct-Q5_K_M.gguf (larger, ~5.3GB)
          - Qwen2.5-Coder-7B-Instruct-Q6_K.gguf (largest, ~6.1GB)
          - Qwen2.5-Coder-7B-Instruct-Q3_K_M.gguf (smallest, ~3.3GB)
      '';
    };

    autoDownload = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically download the model on first activation if not present.
      '';
    };

    # Expose the model path for use by server config
    modelPath = mkOption {
      type = types.str;
      readOnly = true;
      default = "${modelDir}/${cfg.modelFile}";
      description = ''
        Full path to the model file. Used by llama-server config.
      '';
    };
  };

  config = mkIf (llmCfg.enable && cfg.enable) {
    # Add huggingface-hub for downloading models
    home.packages = with pkgs; [
      python3Packages.huggingface-hub
    ];

    # Auto-download model on activation if enabled
    home.activation.downloadQwenModel = mkIf cfg.autoDownload (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        MODEL_DIR="${modelDir}"
        MODEL_FILE="$MODEL_DIR/${cfg.modelFile}"
        HF_REPO="${hfRepo}"

        if [ ! -f "$MODEL_FILE" ]; then
          echo "Qwen model not found at $MODEL_FILE"
          echo "Downloading from HuggingFace: $HF_REPO"
          echo "This may take several minutes..."

          $DRY_RUN_CMD mkdir -p "$MODEL_DIR"
          $DRY_RUN_CMD ${pkgs.python3Packages.huggingface-hub}/bin/hf download \
            "$HF_REPO" \
            --local-dir "$MODEL_DIR" \
            || echo "Warning: Failed to download Qwen model. You can manually download it later with: llama-model-download qwen/${cfg.variant}"
        fi
      ''
    );

    programs.zsh = {
      sessionVariables = {
        QWEN_MODEL_DIR = modelDir;
        QWEN_MODEL_PATH = "${modelDir}/${cfg.modelFile}";
        QWEN_VARIANT = cfg.variant;
      };
      shellAliases = {
        # Simple CLI alias for interactive use
        qwen = "llama-cpp -m ${modelDir}/${cfg.modelFile}";
      };
    };
  };
}
