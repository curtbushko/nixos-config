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
    # Pi.dev CLI installation
    home.packages = with pkgs; [
      # Pi.dev is installed via npm
      nodejs
    ];

    # Install pi.dev globally via npm
    home.activation.installPiDev = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if ! command -v pi &> /dev/null; then
        $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm install -g @pi.dev/cli 2>/dev/null || true
      fi
    '';

    programs.zsh = {
      shellAliases = {
        pi = "npx @pi.dev/cli";
      };
    };
  };
}
