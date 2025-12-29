{
  pkgs,
  inputs,
  lib,
  ...
}: {
  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  # Let home manager manage itself
  programs.home-manager.enable = true;

  # XDG disabled to avoid pulling in unsupported packages
  xdg.enable = false;

  #---------------------------------------------------------------------
  # Home Options - Minimal configuration for Raspberry Pi relay
  # Most modules disabled due to armv7l-linux limited package support
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = false;
    gamedev.enable = false;
    gaming.enable = false;
    git.enable = false;      # Disabled for armv7l compatibility
    k8s.enable = false;
    llm.enable = false;
    programming.enable = false;
    secrets.enable = false;
    shells.enable = false;   # Disabled for armv7l compatibility
    terminals.enable = false;
    tools.enable = false;
    wm = {
      tools.enable = false;
      niri.enable = false;
      rofi.enable = false;
    };
  };

  #---------------------------------------------------------------------
  # Packages - Minimal set for relay server
  # Note: Install packages manually on the system if needed
  #---------------------------------------------------------------------
  home.packages = [
    # Keeping empty for armv7l compatibility
    # Install packages directly on the Raspberry Pi as needed
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "vim";
    PAGER = "less -FirSwX";
  };

  imports = [
    inputs.stylix.homeModules.stylix
  ];

  # Disable stylix - has compatibility issues with armv7l-linux
  stylix.enable = lib.mkForce false;
}
