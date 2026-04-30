{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;

  # Build notesmd-cli from source - CLI for managing Obsidian markdown notes
  # Requires Go >= 1.25.8, so we override with the latest Go version
  notesmd-cli = (pkgs.buildGoModule.override {
    go = pkgs.go_1_26 or pkgs.go;
  }) {
    pname = "notesmd-cli";
    version = "0.3.5";
    src = pkgs.fetchFromGitHub {
      owner = "Yakitrak";
      repo = "notesmd-cli";
      rev = "v0.3.5";
      sha256 = "sha256-uogfh0XK/kR5UrPDyMZicOkj/VuYrz4LzOkGRIfEWCI=";
    };
    vendorHash = null;
    doCheck = false;
  };
in {
  config = mkIf cfg.enable {
    home.packages = [
      notesmd-cli
    ];
  };
}
