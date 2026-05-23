{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
  cfg = config.curtbushko.llm.models.qwen;
  llmCfg = config.curtbushko.llm;

  # Base directory for all llama.cpp models
  modelsBaseDir = "${config.home.homeDirectory}/.local/share/llama-cpp/models";

  # Qwen models subdirectory
  qwenModelsDir = "${modelsBaseDir}/qwen";

  # Specific model directory
  modelDir = "${qwenModelsDir}/${cfg.variant}";

  # HuggingFace repository mapping
  variantRepos = {
    "2.5-coder-7b-instruct-gptq-int4" = "Qwen/Qwen2.5-Coder-7B-Instruct-GPTQ-Int4";
    "2.5-coder-14b-instruct-gptq-int4" = "Qwen/Qwen2.5-Coder-14B-Instruct-GPTQ-Int4";
    "2.5-coder-32b-instruct-gptq-int4" = "Qwen/Qwen2.5-Coder-32B-Instruct-GPTQ-Int4";
  };

  hfRepo = variantRepos.${cfg.variant} or cfg.variant;

in {
  options.curtbushko.llm.models.qwen = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Qwen model support for llama.cpp
      '';
    };

    variant = mkOption {
      type = types.str;
      default = "2.5-coder-7b-instruct-gptq-int4";
      description = ''
        Which Qwen model variant to use.

        Available options:
          - 2.5-coder-7b-instruct-gptq-int4 (default)
          - 2.5-coder-14b-instruct-gptq-int4
          - 2.5-coder-32b-instruct-gptq-int4

        Or specify a custom HuggingFace repository path.
      '';
    };

    modelFile = mkOption {
      type = types.str;
      default = "model.gguf";
      description = ''
        The GGUF model file name within the model directory.
      '';
    };

    autoDownload = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically download the model on first activation if not present.
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

          $DRY_RUN_CMD mkdir -p "$MODEL_DIR"
          $DRY_RUN_CMD ${pkgs.python3Packages.huggingface-hub}/bin/huggingface-cli download \
            "$HF_REPO" \
            --local-dir "$MODEL_DIR" \
            || echo "Warning: Failed to download Qwen model. You can manually download it later with: llama-model-download qwen/${cfg.variant}"
        fi
      ''
    );

    programs.zsh = {
      sessionVariables = {
        LLAMA_CPP_MODEL_DIR = modelsBaseDir;
        QWEN_MODEL_DIR = modelDir;
        QWEN_VARIANT = cfg.variant;
      };
      shellAliases = {
        qwen = "llama-cpp -m ${modelDir}/${cfg.modelFile}";
        qwen-server = "llama-cpp-server -m ${modelDir}/${cfg.modelFile}";
      };
    };

    # Generic llama.cpp model downloader script
    home.file.".local/bin/llama-model-download" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        MODELS_BASE_DIR="${modelsBaseDir}"

        # Known model repositories (can be extended)
        declare -A MODEL_REPOS=(
          # Qwen models
          ["qwen/2.5-coder-7b-instruct-gptq-int4"]="Qwen/Qwen2.5-Coder-7B-Instruct-GPTQ-Int4"
          ["qwen/2.5-coder-14b-instruct-gptq-int4"]="Qwen/Qwen2.5-Coder-14B-Instruct-GPTQ-Int4"
          ["qwen/2.5-coder-32b-instruct-gptq-int4"]="Qwen/Qwen2.5-Coder-32B-Instruct-GPTQ-Int4"
          # Add more models here as needed
        )

        usage() {
          cat << EOF
        Usage: llama-model-download [OPTIONS] <model-family/variant> [huggingface-repo]

        Download llama.cpp models from HuggingFace to local directory.

        Arguments:
          model-family/variant    Model identifier (e.g., qwen/2.5-coder-7b-instruct-gptq-int4)
          huggingface-repo        Optional: Custom HuggingFace repo (e.g., Qwen/Qwen2.5-Coder-7B)

        Options:
          -l, --list             List known models
          -h, --help             Show this help message

        Environment Variables:
          LLAMA_CPP_MODEL_DIR    Base directory for models (default: $MODELS_BASE_DIR)

        Examples:
          # Download a known model
          llama-model-download qwen/2.5-coder-7b-instruct-gptq-int4

          # Download a custom model
          llama-model-download custom/my-model UserName/ModelRepo

          # List available known models
          llama-model-download --list

        Models are downloaded to:
          \$LLAMA_CPP_MODEL_DIR/<model-family>/<variant>/

        Currently configured Qwen model:
          Variant: ${cfg.variant}
          Directory: ${modelDir}
        EOF
        }

        list_models() {
          echo "Known models:"
          for model in "''${!MODEL_REPOS[@]}"; do
            echo "  $model"
            echo "    → ''${MODEL_REPOS[$model]}"
          done
        }

        # Parse arguments
        case "''${1:-}" in
          -h|--help)
            usage
            exit 0
            ;;
          -l|--list)
            list_models
            exit 0
            ;;
          "")
            usage
            exit 1
            ;;
        esac

        MODEL_PATH="$1"
        CUSTOM_REPO="''${2:-}"

        # Determine HuggingFace repository
        if [ -n "$CUSTOM_REPO" ]; then
          HF_REPO="$CUSTOM_REPO"
        elif [ -n "''${MODEL_REPOS[$MODEL_PATH]:-}" ]; then
          HF_REPO="''${MODEL_REPOS[$MODEL_PATH]}"
        else
          echo "Error: Unknown model '$MODEL_PATH'"
          echo ""
          echo "Either provide a HuggingFace repository as second argument, or use --list to see known models."
          exit 1
        fi

        # Determine target directory
        TARGET_DIR="$MODELS_BASE_DIR/$MODEL_PATH"

        echo "Downloading llama.cpp model..."
        echo "  Model: $MODEL_PATH"
        echo "  HuggingFace: $HF_REPO"
        echo "  Target: $TARGET_DIR"
        echo ""

        # Check for huggingface-cli
        if ! command -v huggingface-cli &> /dev/null; then
          echo "Error: huggingface-cli not found"
          echo ""
          echo "The huggingface-hub package should be installed via your Nix configuration."
          echo "If it's missing, you can temporarily install it with:"
          echo "  nix-shell -p python3Packages.huggingface-hub"
          exit 1
        fi

        # Create directory and download
        mkdir -p "$TARGET_DIR"

        echo "Downloading (this may take a while for large models)..."
        if huggingface-cli download "$HF_REPO" --local-dir "$TARGET_DIR"; then
          echo ""
          echo "✓ Download complete!"
          echo "  Model saved to: $TARGET_DIR"
          echo ""
          echo "To use this model with llama-cpp:"
          echo "  llama-cpp -m $TARGET_DIR/model.gguf"
        else
          echo ""
          echo "✗ Download failed!"
          exit 1
        fi
      '';
      executable = true;
    };
  };
}
