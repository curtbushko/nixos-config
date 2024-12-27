{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.llm;
in
{
  options.curtbushko.llm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable llm
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      aider-chat
    ];

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
  };
}
