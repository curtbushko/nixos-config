{
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
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
    cron = {
      enable = true;
      claudeGreeting.enable = true;
    };
    gamedev = {
      enable = true;
      waveform.enable = true;
    };
    gaming.enable = true;
    im.enable = true;
    k8s.enable = true;
    git.enable = true;
    llm = {
      enable = true;

      # Model configuration
      models.qwen = {
        enable = true;
        variant = "2.5-coder-7b-instruct-gguf";
        modelFile = "qwen2.5-coder-7b-instruct-q4_k_m.gguf";
        autoDownload = true;
      };

      # Server configuration (socket activation + slots)
      server = {
        enable = true;
        port = 8080;
        slots = 2;
        # Set to null to start without a model (load via API)
        # Or set to full path: "${config.home.homeDirectory}/.local/share/llama-cpp/models/qwen/2.5-coder-7b-instruct-gptq-int4/model.gguf"
        defaultModel = null;
        idleTimeout = "5min";
        extraArgs = [
          "--ctx-size 4096"
          # "--n-gpu-layers -1"  # Uncomment to use GPU
        ];
      };
    };
    programming.enable = true;
    secrets.enable = true;
    shells.enable = true;
    terminals.enable = true;
    tools.enable = true;
    wm = {
      tools.enable = true;
      niri.enable = true;
      rofi.enable = false;
    };
    # Theme colors managed by flair: run `flair select <theme>`
    theme.wallpaper = "firewatch-green.jpg";

  };

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------
  home.packages = [
    pkgs.crawl
    pkgs.crawlTiles
    pkgs.cachix
    pkgs.tailscale
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.xclicker
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
