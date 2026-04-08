{
  pkgs,
  inputs,
  ...
}: {
  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options - Based on gamingrig but VM-appropriate
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = true;
    git.enable = true;
    im.enable = true;
    k8s.enable = true;
    llm.enable = true;
    programming.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools.enable = true;
    wm = {
      tools.enable = true;
      rofi.enable = false;
    };
    theme.wallpaper = "firewatch-green.jpg";
  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.cachix
    pkgs.tailscale
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    TERM = "xterm-ghostty";
  };

  imports = [
    inputs.stylix.homeModules.stylix
  ];
}
