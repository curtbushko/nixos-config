{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.services.llm;
  cuda = pkgs.cudaPackages_12_6.overrideScope (_final: _prev: {
    cuda_compat = null;
  });
  ds4 = pkgs.callPackage ../../../../packages/ds4 {};
in {
  config = mkIf cfg.enable {
    environment.systemPackages = [
      cuda.cudatoolkit
      cuda.cuda_nvcc
      cuda.cuda_cudart
      cuda.cuda_cccl
      cuda.libcublas
      ds4
      pkgs.binutils
      pkgs.gcc
      pkgs.gnumake
    ];

    environment.variables = {
      CUDA_HOME = "${cuda.cudatoolkit}";
      CUDA_PATH = "${cuda.cudatoolkit}";
    };
  };
}
