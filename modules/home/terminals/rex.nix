{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
  cfg = config.ns.terminals.rex;
  rexCli = "${cfg.appPath}/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
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
  initLua = builtins.readFile ./rex/init.lua;
in {
  options.ns.terminals.rex.appPath = mkOption {
    type = types.str;
    default = "/Applications/Rex Beta.app";
    description = "Path to the separately installed Rex application bundle.";
  };

  options.ns.terminals.rex.lan = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to run a persistent Rex server with an unencrypted, anonymous network listener granting full user access.";
    };
    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0:7297";
      description = "Address and port for Rex's anonymous listener. The default binds all IPv4 interfaces; use only on trusted networks.";
    };
  };

  options.ns.terminals.rex.enable = mkOption {
    type = types.bool;
    default = config.ns.terminals.enable && pkgs.stdenv.hostPlatform.isDarwin;
    description = ''
      Whether to install Rex's init.lua and HerdR-style keys.
      On macOS, also configure a theme matching Ghostty; install the app
      separately, then import ~/.config/rex/themes/flair in Rex's theme settings.
    '';
  };

  config = mkIf cfg.enable (lib.mkMerge [
    {
      xdg.configFile = {
        "rex/init.lua" = {
          text = initLua;
          force = true;
        };
        "rex/cycle.lua".source = ./rex/cycle.lua;
      };
    }
    (mkIf pkgs.stdenv.hostPlatform.isDarwin {
      assertions = [
        {
          assertion = config.ns.terminals.enable;
          message = "ns.terminals.rex requires ns.terminals.enable for the Ghostty theme.";
        }
      ];

      targets.darwin.defaults."com.superlogical.rex" = {
        # Free Cmd+H for pane/tab navigation in both app variants.
        NSUserKeyEquivalents = {
          "Hide Rex" = "@$^h";
          "Hide Rex Beta" = "@$^h";
        };
        "rex.client.remoteControl" = true;
        "rex.server.tailnet-enabled" = false;
        # launchd owns the LAN server; don't let the app restart it without flags.
        "rex.server.automatic-restart-enabled" = !cfg.lan.enable;
        # Match Ghostty's terminal typography.
        "Workspace.terminalFontName" = "JetBrainsMono Nerd Font";
        "Workspace.terminalFontStyle" = "Medium";
        "Workspace.terminalFontPointSize" = 12.0;
      };

      launchd.agents.rex-server = mkIf cfg.lan.enable {
        enable = true;
        config = {
          ProgramArguments = [
            rexCli
            "server"
            "run"
            "--extra-listen"
            cfg.lan.listenAddress
            "--allow-anonymous"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 30;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/rex-server.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/rex-server.log";
        };
      };

      home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];
      home.file.".local/bin/rex".source =
        config.lib.file.mkOutOfStoreSymlink
        rexCli;

      # Rex's importer rejects Home Manager's usual store symlinks.
      home.activation.rexTheme = lib.hm.dag.entryAfter ["linkGeneration"] ''
        run ${pkgs.coreutils}/bin/env PATH=${lib.escapeShellArg (lib.makeBinPath [pkgs.coreutils pkgs.diffutils])} \
          ${pkgs.bash}/bin/bash ${../scripts/rex-theme-install} \
          ${themeFile} ${lib.escapeShellArg "${config.xdg.configHome}/rex/themes/flair"}
      '';
      home.activation.rexConfigReload = lib.hm.dag.entryAfter ["linkGeneration" "rexTheme"] ''
        # Reload an existing server without launching Rex during activation.
        rex_cli=${lib.escapeShellArg rexCli}
        if [[ -x "$rex_cli" ]] && "$rex_cli" --autostart=false server status >/dev/null 2>&1; then
          run "$rex_cli" --autostart=false config reload
        fi
      '';
    })
  ]);
}
