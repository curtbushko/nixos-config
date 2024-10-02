{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  home.packages = with pkgs;
    [
    ]
    ++ (lib.optionals isLinux [
      minecraft
      vulkan-loader
      glfw
      #prismlauncher
      (prismlauncher.override {additionalLibs = [vulkan-loader];})
    ]);
}
