{
  pkgs,
  inputs,
  ...
}: {
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";

  # Let home manager manage itself
  programs.home-manager.enable = true;
  xdg.enable = true;

  #---------------------------------------------------------------------
  # Home Options
  #---------------------------------------------------------------------
  curtbushko = {
    browsers.enable = true;
    cron.enable = true;
    gaming.enable = true;
    git.enable = true;
    k8s.enable = true;
    llm = {
      enable = true;
      # Model configuration for Qwen (GGUF for llama-cpp)
      models.qwen = {
        enable = true;
        autoDownload = false;  # Download manually to avoid timeout
      };
      # oMLX server (optimized MLX with tiered caching for Apple Silicon)
      server = {
        enable = true;
        port = 8080;
        omlxModelDir = "~/models";  # Download models via oMLX admin UI
      };
    };
    programming.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools.enable = true;
    wm.rectangle.enable = true;
    # Theme colors managed by flair: run `flair select <theme>`
    theme.wallpaper = "cyberpunk_2077_phantom_liberty_katana.jpg";
  };

  #---------------------------------------------------------------------
  # oMLX LLM aliases (optimized MLX for Apple Silicon)
  #---------------------------------------------------------------------
  programs.zsh.shellAliases = {
    # oMLX commands (tiered caching, continuous batching)
    omlx-start = "omlx serve --model-dir ~/models";
    omlx-admin = "open http://localhost:8080/admin";
    omlx-download = "omlx download";
  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    # Darwin only
    pkgs.cachix
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.podman
    pkgs.obsidian
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
    QT_QPA_PLATFORMTHEME = "kde";
  };

  imports = [
    inputs.stylix.homeModules.stylix
  ];
}
