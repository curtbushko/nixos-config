# Tracktion Waveform Free DAW
# Downloads and packages the .deb release from Tracktion
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf mkEnableOption;
  cfg = config.curtbushko.gamedev.waveform;
  gamedevCfg = config.curtbushko.gamedev;
  isLinux = pkgs.stdenv.isLinux;

  # Waveform package definition
  waveformPkg = pkgs.stdenv.mkDerivation rec {
    pname = "waveform-free";
    version = "13.5.8";

    src = pkgs.fetchurl {
      url = "https://cdn.tracktion.com/file/tracktiondownload/w13/1358/waveform13_${version}_amd64.deb";
      sha256 = "sha256-tHrsv2kMxBYUBcbOW1Ae9T0Eu3b1hrsyYJhGjmsu4UE=";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      makeWrapper
    ];

    # Runtime dependencies for autoPatchelfHook to add to RPATH
    runtimeDependencies = with pkgs; [
      curl.out
    ];

    buildInputs = with pkgs; [
      # Audio
      alsa-lib
      libjack2
      pipewire

      # Graphics/UI
      freetype
      fontconfig
      libGL
      libglvnd
      xorg.libX11
      xorg.libXext
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXcursor
      xorg.libXrender
      xorg.libXcomposite

      # Other dependencies
      curl
      libusb1
      libxkbcommon
      stdenv.cc.cc.lib
    ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r usr/* $out/ || true
      cp -r opt/* $out/opt/ || true

      # Find and wrap the main binary
      mkdir -p $out/bin
      if [ -f "$out/opt/tracktion/waveform13/Waveform13" ]; then
        makeWrapper $out/opt/tracktion/waveform13/Waveform13 $out/bin/waveform \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"
      elif [ -f "$out/opt/tracktion/waveform/Waveform" ]; then
        makeWrapper $out/opt/tracktion/waveform/Waveform $out/bin/waveform \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"
      fi

      runHook postInstall
    '';

    meta = with lib; {
      description = "Tracktion Waveform 13 Free - Professional DAW";
      homepage = "https://www.tracktion.com/products/waveform-free";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "Waveform13";
    };
  };
in {
  options.curtbushko.gamedev.waveform = {
    enable = mkEnableOption "Tracktion Waveform Free DAW";

    package = mkOption {
      type = types.package;
      default = waveformPkg;
      description = "The Waveform package to use";
    };
  };

  config = mkIf (gamedevCfg.enable && cfg.enable && isLinux) {
    home.packages = [
      cfg.package
    ];
  };
}
