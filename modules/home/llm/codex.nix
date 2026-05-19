{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.llm;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # OpenAI Codex CLI (if available via packages)
      # For now, assuming it's installed via other means
    ];

    programs.zsh = {
      sessionVariables = {
        CODEX_HOME = "${config.home.homeDirectory}/.codex";
        OPENAI_API_KEY = ""; # Set via environment or secrets management
      };
      shellAliases = {
        codex = "codex";
        cx = "codex";
      };
    };

    # Deploy Codex global instructions (AGENTS.md)
    home.file.".codex/AGENTS.md".source = ./codex/AGENTS.md;

    # Deploy Codex skills as individual AGENTS.md files
    home.file.".codex/skills".source = ./codex/skills;

    # Codex validation scripts
    home.file.".codex/scripts" = {
      source = ./codex/scripts;
      recursive = true;
      executable = true;
    };
  };
}
