{pkgs, ...}: {
  home.packages = with pkgs; [
    aseprite
    audacity
    blender
    # davinci-resolve-studio Disable until https://github.com/NixOS/nixpkgs/issues/341634
    inkscape
    gimp
    krita
    olive-editor
    godot_4
  ];
}
