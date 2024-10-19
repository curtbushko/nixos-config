{pkgs, ...}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  home.packages = with pkgs;
    []
    ++ (lib.optionals isLinux [
      aseprite
      audacity
      blender
      # davinci-resolve-studio Disable until https://github.com/NixOS/nixpkgs/issues/341634
      inkscape
      gimp
      krita
      olive-editor
      godot_4
    ]);
}
