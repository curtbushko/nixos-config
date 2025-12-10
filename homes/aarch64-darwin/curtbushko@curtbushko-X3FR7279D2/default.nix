{
  pkgs,
  inputs,
  ...
}: {
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "18.09";

  # Let home manager manage itself
  programs.home-manager.enable = true;
  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options
  #---------------------------------------------------------------------
  curtbushko = {
    git.enable = true;
    k8s.enable = true;
    programming.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools.enable = true;
    theme = {
      name = "gruvbox-material";
      wallpaper = "green-pasture.jpg";
    };

  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    # Darwin only
    pkgs.cachix
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.podman
    pkgs.python312
    pkgs.terraform
    pkgs.helm
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
