{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.llm;
in {
  config = mkIf cfg.enable {
    # CUDA toolkit removed - ollama will use NVIDIA drivers for GPU acceleration
    # environment.systemPackages = with pkgs; [
    #   cudatoolkit
    # ];

  };
}
