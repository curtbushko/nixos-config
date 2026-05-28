{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.llm;
in {
  options.curtbushko.llm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable llm
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
        # llama-cpp with CUDA is installed at system level (see systems/x86_64-linux/gamingrig/default.nix)
        # Don't install here to avoid shadowing the CUDA version
        inputs.llm-agents.packages.${system}.rtk
        inputs.llm-agents.packages.${system}.ccusage
        pkgs.python3Packages.huggingface-hub
    ];

    # RTK config
    xdg.configFile."rtk/config.toml".source = ./rtk-config.toml;

    # Generic llama.cpp model downloader script
    home.file.".local/bin/llama-model-download" = {
      text = let
        modelsBaseDir = "${config.home.homeDirectory}/.local/share/llama-cpp/models";
      in ''
        #!/usr/bin/env bash
        set -euo pipefail

        MODELS_BASE_DIR="${modelsBaseDir}"

        # Known model repositories (can be extended)
        declare -A MODEL_REPOS=(
          # Qwen models (GGUF format)
          ["qwen/2.5-coder-7b-instruct-gguf"]="Qwen/Qwen2.5-Coder-7B-Instruct-GGUF"
          ["qwen/2.5-coder-14b-instruct-gguf"]="Qwen/Qwen2.5-Coder-14B-Instruct-GGUF"
          ["qwen/2.5-coder-32b-instruct-gguf"]="Qwen/Qwen2.5-Coder-32B-Instruct-GGUF"
          ["qwen/2.5-coder-7b-instruct-gguf-bartowski"]="bartowski/Qwen2.5-Coder-7B-Instruct-GGUF"
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
          llama-model-download llama/3.1-8b-instruct UserName/ModelRepo

          # List available known models
          llama-model-download --list

        Models are downloaded to:
          \$LLAMA_CPP_MODEL_DIR/<model-family>/<variant>/
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

        # Check for hf command
        if ! command -v hf &> /dev/null; then
          echo "Error: hf command not found"
          echo ""
          echo "The huggingface-hub package should be installed via your Nix configuration."
          echo "If it's missing, you can temporarily install it with:"
          echo "  nix-shell -p python3Packages.huggingface-hub"
          exit 1
        fi

        # Create directory and download
        mkdir -p "$TARGET_DIR"

        echo "Downloading (this may take a while for large models)..."
        if hf download "$HF_REPO" --local-dir "$TARGET_DIR"; then
          echo ""
          echo "✓ Download complete!"
          echo "  Model saved to: $TARGET_DIR"
          echo ""
          echo "To use this model:"
          echo "  llama-cpp -m $TARGET_DIR/model.gguf"
          echo "  llama-load-model $TARGET_DIR/model.gguf"
        else
          echo ""
          echo "✗ Download failed!"
          exit 1
        fi
      '';
      executable = true;
    };

    # Base model directory environment variable
    programs.zsh.sessionVariables = {
      LLAMA_CPP_MODEL_DIR = "${config.home.homeDirectory}/.local/share/llama-cpp/models";
    };
  };

  imports = [
    ./claude.nix
    ./codex.nix
    ./llmfit.nix
    ./opencode.nix
    ./openchamber.nix
    ./pi
    ./models/qwen.nix
  ];
}
