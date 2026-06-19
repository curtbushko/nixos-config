{
  lib,
  stdenv,
  fetchFromGitHub,
  cudaPackages_12_6 ? null,
  darwin,
  cudaArch ? "sm_89",
}:
let
  isDarwin = stdenv.hostPlatform.isDarwin;
  cudaPackages =
    if isDarwin
    then null
    else
      cudaPackages_12_6.overrideScope (_final: _prev: {
        cuda_compat = null;
      });
  buildStdenv =
    if isDarwin
    then stdenv
    else cudaPackages.backendStdenv;
  buildTargets = "ds4 ds4-server ds4-bench ds4-eval ds4-agent";
in
  buildStdenv.mkDerivation {
    pname = "ds4";
    version = "0-unstable-2026-06-11";

    src = fetchFromGitHub {
      owner = "antirez";
      repo = "ds4";
      rev = "d881f2a05e8ff6bec001315a36b794b4aa310173";
      hash = "sha256-jjpQTaWfvYG0fmmPiA/pbD3YyYseyPygeCW87C5IDzI=";
    };

    strictDeps = true;

    nativeBuildInputs = lib.optionals (!isDarwin) [
      cudaPackages.cuda_nvcc
    ];

    buildInputs =
      if isDarwin
      then [
        darwin.apple_sdk.frameworks.Foundation
        darwin.apple_sdk.frameworks.Metal
      ]
      else [
        cudaPackages.cuda_cudart
        cudaPackages.libcublas
        cudaPackages.cuda_cccl
      ];

    buildPhase = ''
      runHook preBuild
    ''
    + lib.optionalString isDarwin ''
      make ${buildTargets} NATIVE_CPU_FLAG=
    ''
    + lib.optionalString (!isDarwin) ''
      make ${buildTargets} \
        NVCC=nvcc \
        NATIVE_CPU_FLAG= \
        "NVCCFLAGS=-O3 --use_fast_math -arch=${cudaArch} -Xcompiler -pthread" \
        "CUDA_LDLIBS=-lm -Xcompiler -pthread -lcudart -lcublas"
    ''
    + ''
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/ds4
      cp ds4 ds4-server ds4-bench ds4-eval ds4-agent $out/bin/
      cp download_model.sh $out/share/ds4/

      substituteInPlace $out/share/ds4/download_model.sh \
        --replace 'cd "$ROOT"' '# cd "$ROOT"  # patched by Nix: use $PWD instead'

      cat >$out/bin/ds4-download-model <<'EOF'
      #!/bin/sh
      : "''${DS4_GGUF_DIR:=$PWD/gguf}"
      export DS4_GGUF_DIR
      script="PLACEHOLDER"
      exec "$script" "$@"
      EOF
      substituteInPlace $out/bin/ds4-download-model --replace PLACEHOLDER "$out/share/ds4/download_model.sh"
      chmod +x $out/bin/ds4-download-model

      runHook postInstall
    '';

    meta = {
      description = "DeepSeek V4 Flash inference engine (CUDA build)";
      homepage = "https://github.com/antirez/ds4";
      license = lib.licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      mainProgram = "ds4";
    };
  }
