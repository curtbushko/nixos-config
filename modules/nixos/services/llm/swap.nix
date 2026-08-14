{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.services.llm.swap;

  # CUDA-enabled llama.cpp (same override used in gamingrig/default.nix).
  llamaCppCuda = pkgs.llama-cpp.override {
    cudaSupport = true;
    cudaPackages = pkgs.cudaPackages_12_6.overrideScope (_final: _prev: {
      cuda_compat = null;
    });
  };

  modelDir = "${cfg.modelsBase}/qwen/3.8-27b-gguf";

  # Backend command llama-swap runs on demand.
  # ${PORT} is expanded by llama-swap, not the shell.
  qwen38Cmd = lib.concatStringsSep " " [
    "${llamaCppCuda}/bin/llama-server"
    "-m ${modelDir}/${cfg.qwen38.modelFile}"
    "--mmproj ${modelDir}/mmproj-BF16.gguf"
    "--host 127.0.0.1 --port \${PORT}"
    "-c ${toString cfg.qwen38.ctx}"
    "--parallel 1 --fit on"
    "--cache-type-k q8_0 --cache-type-v q8_0"
    "-b 1024 -ub 512"
    "--flash-attn on --no-context-shift --no-mmproj-offload"
    "--spec-type draft-mtp --spec-draft-n-max 5 --spec-default"
    "--cache-type-k-draft q4_0 --cache-type-v-draft q4_0"
    "--threads 8 --jinja"
    "--reasoning ${cfg.qwen38.reasoning}"
    "--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0"
    "--presence-penalty 0.0 --repeat-penalty 1.0"
  ];

  swapConfig = {
    healthCheckTimeout = 500; # seconds llama-swap will wait for backend to become healthy
    models = {
      "qwen3.8-27b" = {
        cmd = qwen38Cmd;
        ttl = cfg.idleSeconds;
        # llama-swap probes /health before proxying
        checkEndpoint = "/health";
      };
    };
  };

  configFile = (pkgs.formats.yaml {}).generate "llama-swap.yaml" swapConfig;
in {
  options.ns.services.llm.swap = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Run llama-swap as a system service: a proxy that starts/stops
        llama-server backends on demand and idles them after
        `idleSeconds` of inactivity.
      '';
    };

    listen = mkOption {
      type = types.str;
      default = "0.0.0.0:8080";
      description = "host:port llama-swap listens on";
    };

    idleSeconds = mkOption {
      type = types.int;
      default = 600;
      description = "Unload a model after this many seconds of no requests";
    };

    modelsBase = mkOption {
      type = types.str;
      default = "/home/curtbushko/.local/share/llama-cpp/models";
      description = "Base directory containing GGUF models";
    };

    qwen38 = {
      modelFile = mkOption {
        type = types.str;
        default = "Qwen3.8-27B-UD-Q2_K_XL.gguf";
        description = "Filename of the Qwen3.8 GGUF under $modelsBase/qwen/3.8-27b-gguf/";
      };
      ctx = mkOption {
        type = types.int;
        default = 32768;
        description = "Context length for Qwen3.8";
      };
      reasoning = mkOption {
        type = types.enum ["on" "off" "auto"];
        default = "off";
        description = "Qwen3.8 reasoning mode";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-swap = {
      description = "llama-swap: on-demand llama.cpp proxy";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        # Runs as root so it inherits GPU access without extra group plumbing.
        # Backend llama-server processes are children of this service.
        ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config ${configFile} --listen ${cfg.listen}";
        Restart = "on-failure";
        RestartSec = 5;
        # Model files live in the user's home; llama-server needs to read them.
        # Running as root sidesteps permission issues; if you'd rather run as a
        # user, add a `User =` line and ensure they can read modelsBase + have
        # video/render group membership.
      };
    };
  };
}
