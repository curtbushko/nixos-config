{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.gaming;
  isLinux = pkgs.stdenv.isLinux;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
      ]
      ++ (lib.optionals isLinux [
        # minecraft 2025-09-15 minecraft package is broken
        openjdk25
        vulkan-loader
        glfw
        #prismlauncher
        (prismlauncher.override {additionalLibs = [vulkan-loader];})
      ]);
  };
}
