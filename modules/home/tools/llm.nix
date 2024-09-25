{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: {
  home.packages = [pkgs.aider-chat];

  home.file.".aider.conf.yml" = {
    text = with config.lib.stylix.colors.withHashtag; ''

      # Docs: https://aider.chat/docs/config/aider_conf.html

      #######
      # Main:

      model: ollama/llama3.1:8b
      check-update: false
      show-model-warnings: false


      ###############
      # Git Settings:

      ## Enable/disable auto commit of LLM changes (default: True)
      auto-commits: false

      ## Attribute aider code changes in the git author name (default: True)
      attribute-author: false

      ## Attribute aider commits in the git committer name (default: True)
      attribute-committer: false

      ###############
      # Output Settings:

      dark-mode: true
      pretty: true

      ## Set the color for user input (default: #00cc00)
      user-input-color: ${base0D}

      ## Set the color for tool output (default: None)
      #tool-output-color: ${base05}

      ## Set the color for tool error messages (default: #FF2222)
      tool-error-color: ${base08}

      ## Set the color for tool warning messages (default: #FFA500)
      tool-warning-color: ${base0A}

      ## Set the color for assistant output (default: #0088ff)
      assistant-output-color: ${base0C}

      ## Set the markdown code theme (default: default, other options include monokai, solarized-dark, solarized-light)
      code-theme: monokai

      ## Show diffs when committing changes (default: False)
      show-diffs: false

    '';
  };
}
