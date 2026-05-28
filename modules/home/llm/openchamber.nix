{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.llm;

  # OpenChamber version
  version = "1.11.7";

  # Architecture-specific source
  darwinSrc =
    if pkgs.stdenv.hostPlatform.isAarch64
    then {
      url = "https://github.com/openchamber/openchamber/releases/download/v${version}/OpenChamber-${version}-darwin-aarch64.app.tar.gz";
      sha256 = "0f2a48kzh261c0rg5hc2rxg7j40dr6v71jsl96w19y2mvm1vr8vp";
    }
    else {
      url = "https://github.com/openchamber/openchamber/releases/download/v${version}/OpenChamber-${version}-darwin-x86_64.app.tar.gz";
      sha256 = "0mssssa384rlyqmygmvq8qcfbzyq5l1jghshzrzmm9rsc12hn7wk";
    };

  openchamber = pkgs.stdenv.mkDerivation {
    pname = "openchamber";
    inherit version;

    src = pkgs.fetchurl darwinSrc;

    # Don't automatically enter the OpenChamber.app directory
    sourceRoot = ".";

    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r OpenChamber.app $out/Applications/

      # Create wrapper script
      mkdir -p $out/bin
      cat > $out/bin/openchamber << EOF
      #!/bin/sh
      exec "$out/Applications/OpenChamber.app/Contents/MacOS/OpenChamber" "\$@"
      EOF
      chmod +x $out/bin/openchamber

      runHook postInstall
    '';

    meta = with lib; {
      description = "Desktop and web interface for OpenCode AI agent";
      homepage = "https://openchamber.dev";
      platforms = platforms.darwin;
    };
  };
in {
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # OpenChamber installation
    home.packages = [ openchamber ];

    programs.zsh = {
      shellAliases = {
        oc-ui = "openchamber";
      };
    };
  };
}
