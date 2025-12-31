{
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  ...
}: {
  home.stateVersion = "25.11";
  home.username = "deck";
  home.homeDirectory = "/home/deck";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = true;
    gaming.enable = true;
    git.enable = true;
    programming.enable = false;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools.enable = true;
    wm = {
      tools.enable = false;
      niri.enable = false;
      rofi.enable = false;
    };
    theme = {
      name = "gruvbox-material";
      wallpaper = "cyberpunk-three.png";
    };
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

  # Set zsh as default shell
  home.activation.setDefaultShell = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD /usr/bin/chsh -s ${pkgs.zsh}/bin/zsh || true
  '';


  imports = [
    inputs.stylix.homeModules.stylix
    ./tailscale.nix
  ];
}
