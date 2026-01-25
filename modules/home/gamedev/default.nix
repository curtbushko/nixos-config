{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.gamedev;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.curtbushko.gamedev = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tools
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      []
      ++ (lib.optionals isLinux [
        ardour
        audacity
        blender
        # davinci-resolve-studio Disable until https://github.com/NixOS/nixpkgs/issues/341634
        inkscape
        gimp
        krita
        godot_4
        lmms
        obs-studio
        zrythm
        # Vulkan SDK
        vulkan-tools
        vulkan-headers
        vulkan-loader
        vulkan-validation-layers
      ]);

    home.sessionVariables = lib.mkIf isLinux {
      VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
      VULKAN_SDK = "${pkgs.vulkan-headers}";
      LD_LIBRARY_PATH = "${pkgs.vulkan-loader}/lib:${pkgs.vulkan-validation-layers}/lib\${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}";
    };
  };

  imports = [
    ./waveform.nix
  ];
}
