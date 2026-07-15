{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.services.wm;
in {
  config = mkIf cfg.enable {
    fonts = {
      fontDir.enable = true;
    };

    fonts.packages = with pkgs; [
      fira-code
      font-awesome_5
      jetbrains-mono
      intel-one-mono
      nerd-fonts.symbols-only # symbols icon only
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
      nerd-fonts.sauce-code-pro
      noto-fonts
      noto-fonts-color-emoji
      powerline-fonts
      freetype # needed by Wine
    ];

    fonts.fontconfig = {
      enable = true;
      antialias = true;
      # Fixes antialias blur
      hinting = {
        enable = true;
        style = "full";
        autohint = true;
      };
      subpixel = {
        rgba = "rgb"; # Nakes it bolder
        lcdfilter = "default";
      };
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font Mono" "Noto Mono"];
        sansSerif = ["Noto Sans" "JetBrainsMono Nerd Font Mono"];
        serif = ["Noto Serif" "Noto Sans"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
