{
  config,
  pkgs,
  ...
}: {
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
    libGLU libGL
    xorg.libXi xorg.libXmu freeglut
    xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib 
    ncurses5
    stdenv.cc
    binutils
  ];
  environment.variables.CUDA_PATH=${pkgs.cudatoolkit}
    # export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib
  environment.variables.EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
  environment.variables.EXTRA_CCFLAGS="-I/usr/include"
}
