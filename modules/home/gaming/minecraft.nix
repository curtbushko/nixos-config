{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.gaming;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        openjdk25
        vulkan-loader
        glfw
        packwiz
        #prismlauncher
        (prismlauncher.override {additionalLibs = [vulkan-loader];})
      ];
  };
}
