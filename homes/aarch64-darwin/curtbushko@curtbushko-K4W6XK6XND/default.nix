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
  ns = {
    browsers.enable = true;
    cron = {
      enable = true;
      killExchangeProcesses.enable = true;
    };
    git.enable = true;
    k8s.enable = true;
    programming.enable = true;
    scripts.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals = {
      enable = true;
      rex = {
        enable = true;
        lan.enable = false;
      };
    };
    tools.enable = true;
    llm = {
      enable = true;
      pi.enabledModels = ["github-copilot/*"];
    };
    wm.rectangle.enable = true;
    # Theme colors managed by flair: run `flair select <theme>`
    theme.wallpaper = "green-pasture.jpg";
  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    (pkgs.callPackage ../../../packages/tasknotes-tools {})
    inputs.mtn.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Darwin only
    pkgs.cachix
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.podman
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenv
    pkgs.pre-commit
    pkgs.terraform
    pkgs.kubernetes-helm
    pkgs.awscli2
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
  };
}
