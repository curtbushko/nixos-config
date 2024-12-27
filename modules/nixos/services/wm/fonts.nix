{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.wm;
in
{
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
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-extra
      noto-fonts-emoji
      powerline-fonts
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
        monospace = ["FiraCode Nerd Font Mono" "Noto Mono"];
        #monospace = ["JetbrainsMono Nerd Font Mono" "Noto Mono"];
        sansSerif = ["FiraCode Nerd Font Mono" "Noto Mono"];
        #sansSerif = ["JetbrainsMono Nerd Font Mono" "Noto Mono"];
        serif = ["FiraCode Nerd Font Mono" "Noto Mono"];
        #serif = ["JetbrainsMono Nerd Font Mono" "Noto Mono"];
        emoji = ["Noto Color Emoji"];
        #emoji = ["Noto Color Emoji"];
      };
    };
  };
}
