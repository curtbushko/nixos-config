{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
  cfg = config.ns.terminals.rex;
  # Reuse Ghostty's rendered colors rather than maintaining a second palette.
  themeLines =
    builtins.filter
    (line:
      builtins.any (prefix: lib.hasPrefix prefix line) [
        "foreground = "
        "background = "
        "palette = "
        "cursor-color = "
        "cursor-text = "
        "selection-background = "
        "selection-foreground = "
      ])
    (lib.splitString "\n" config.xdg.configFile."ghostty/config".text);
  themeFile = pkgs.writeText "rex-flair-theme" (lib.concatStringsSep "\n" themeLines + "\n");
  whichkey = inputs.rex-whichkey.lib.mkPackage {
    inherit pkgs;
    rexCli = "${cfg.appPath}/Contents/Helpers/Rex Server.app/Contents/MacOS/rex";
  };
  initLua =
    builtins.replaceStrings
    ["\"@REX_WHICHKEY_PLUGIN@\""]
    [(builtins.toJSON (toString whichkey.plugin))]
    (builtins.readFile ./rex/init.lua);
in {
  options.ns.terminals.rex.appPath = mkOption {
    type = types.str;
    default = "/Applications/Rex Beta.app";
    description = "Path to the separately installed Rex application bundle.";
  };

  options.ns.terminals.rex.enable = mkOption {
    type = types.bool;
    default = config.ns.terminals.enable && pkgs.stdenv.hostPlatform.isDarwin;
    description = ''
      Whether to configure Rex with HerdR-style keys and a theme matching Ghostty.
      Install the invite-only macOS app separately, then import and select
      ~/.config/rex/themes/flair in Rex's theme settings.
    '';
  };

  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    assertions = [
      {
        assertion = config.ns.terminals.enable;
        message = "ns.terminals.rex requires ns.terminals.enable for the Ghostty theme.";
      }
    ];

    targets.darwin.defaults."com.superlogical.rex"."rex.client.remoteControl" = true;

    home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];
    home.file.".local/bin/rex".source =
      config.lib.file.mkOutOfStoreSymlink
      "${cfg.appPath}/Contents/Helpers/Rex Server.app/Contents/MacOS/rex";

    xdg.configFile."rex/init.lua" = {
      text = initLua;
      force = true;
    };
    # Rex's importer rejects Home Manager's usual store symlinks.
    home.activation.rexTheme = lib.hm.dag.entryAfter ["linkGeneration"] ''
      run ${pkgs.coreutils}/bin/env PATH=${lib.escapeShellArg (lib.makeBinPath [pkgs.coreutils pkgs.diffutils])} \
        ${pkgs.bash}/bin/bash ${../scripts/rex-theme-install} \
        ${themeFile} ${lib.escapeShellArg "${config.xdg.configHome}/rex/themes/flair"}
    '';
    home.activation.rexConfigReload = lib.hm.dag.entryAfter ["linkGeneration" "rexTheme"] ''
      # Reload an existing server without launching Rex during activation.
      rex_cli=${lib.escapeShellArg "${cfg.appPath}/Contents/Helpers/Rex Server.app/Contents/MacOS/rex"}
      if [[ -x "$rex_cli" ]] && "$rex_cli" --autostart=false server status >/dev/null 2>&1; then
        run "$rex_cli" --autostart=false config reload
      fi
    '';
  };
}
