{
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  system,
  ...
}: {
  home.stateVersion = "18.09";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = true;
    gamedev.enable = true;
    gaming.enable = true;
    im.enable = true;
    k8s.enable = true;
    git.enable = true;
    llm.enable = true;
    programming.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools.enable = true;
    wm = {
      tools.enable = true;
      waybar.enable = true;
      hyprland.enable = true;
      niri.enable = true;
      rofi.enable = true;
    };
    theme = {
      name = "gruvbox-material";
      wallpaper = "exploring_new_worlds.jpg";
    };

  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.crawl
    pkgs.crawlTiles

    pkgs.cachix
    pkgs.tailscale
    inputs.neovim.packages.${system}.default
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    TERM = "xterm-256color";
  };

  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];
}
