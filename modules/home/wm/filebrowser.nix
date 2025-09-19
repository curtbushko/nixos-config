{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
      ]
      ++ (lib.optionals isLinux [
        adw-gtk3
        nautilus
      ]);

    home.file.".config/gtk-3.0/bookmarks".text = ''
      file://${config.home.homeDirectory}/
      file://${config.home.homeDirectory}/Downloads
      file://${config.home.homeDirectory}/workspace/github.com/curtbushko/nixos-config NixOS Config
    '';

    dconf.settings = {
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        show-hidden-files = false;
        default-sort-order = "name";
        default-sort-in-reverse-order = false;
        always-use-location-entry = false;
        show-directory-item-counts = "on-this-computer";

        show-delete-permanently = true;
      };
    };
  };
}
