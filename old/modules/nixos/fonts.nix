{pkgs, ...}: {
  # Fonts are nice to have
  #
  fonts = {
    fontDir.enable = true;
  };

  fonts.packages = with pkgs; [
    fira-code
    font-awesome_5
    jetbrains-mono
    nerdfonts
    noto-fonts
    noto-fonts-extra
    noto-fonts-emoji
    powerline-fonts
  ];

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    defaultFonts = {
      monospace = ["JetbrainsMono Nerd Font Mono" "Noto Mono"];
      sansSerif = ["JetbrainsMono Nerd Font Mono" "Noto Mono"];
      serif = ["JetbrainsMono Nerd Font Mono" "Noto Mono"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
