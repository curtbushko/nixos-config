{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.llm;
in
{
  config = mkIf cfg.enable {
    # Taken from: https://nixos.wiki/wiki/CUDA
    # I figured it'd be better to install at the system level instead of in a shell
    environment.systemPackages = with pkgs; [
      git
      gitRepo
      gnupg
      autoconf
      curl
      procps
      gnumake
      util-linux
      m4
      gperf
      unzip
      cudatoolkit
      linuxPackages.nvidia_x11
      libGLU
      libGL
      xorg.libXi
      xorg.libXmu
      freeglut
      xorg.libXext
      xorg.libX11
      xorg.libXv
      xorg.libXrandr
      zlib
      ncurses5
      stdenv.cc
      binutils
    ];
    environment.variables.CUDA_PATH = "${pkgs.cudatoolkit}";
    # export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib
    environment.variables.EXTRA_LDFLAGS = "-L/lib -L${pkgs.stdenv.cc.cc.lib} -L${pkgs.linuxPackages.nvidia_x11}/lib -L${pkgs.glib.out}/lib -L${pkgs.libGLU}/lib -L${pkgs.libGL}/lib";
    environment.variables.EXTRA_CCFLAGS = "-I/usr/include";
  };
}
