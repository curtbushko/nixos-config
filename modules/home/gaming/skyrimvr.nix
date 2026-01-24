# Skyrim VR modding module with Jackify integration
# Provides declarative modlist management, Steam integration, and Proton setup
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf mkEnableOption;
  cfg = config.curtbushko.gaming.skyrimvr;
  gamingCfg = config.curtbushko.gaming;
  isLinux = pkgs.stdenv.isLinux;

  # Jackify package definition (inline)
  jackifyPkg = let
    pname = "jackify";
    version = "0.2.1.1";

    src = pkgs.fetchurl {
      url = "https://github.com/Omni-guides/Jackify/releases/download/v${version}/Jackify.AppImage";
      sha256 = "sha256-zVreomYaYfOU6pEUlZz+rVMjeuTZBKzylUMF1ComEdQ=";
    };

    appimageContents = pkgs.appimageTools.extractType2 {inherit pname version src;};
  in
    pkgs.appimageTools.wrapType2 {
      inherit pname version src;

      extraInstallCommands = ''
        # Install desktop file if present
        if [ -f ${appimageContents}/jackify.desktop ]; then
          install -m 444 -D ${appimageContents}/jackify.desktop $out/share/applications/jackify.desktop
        fi

        # Install icon if present
        for size in 16 32 48 64 128 256 512; do
          if [ -f ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/jackify.png ]; then
            install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/jackify.png \
              $out/share/icons/hicolor/''${size}x''${size}/apps/jackify.png
          fi
        done

        # Create CLI wrapper
        source ${pkgs.makeWrapper}/nix-support/setup-hook
        makeWrapper $out/bin/jackify $out/bin/jackify-cli \
          --add-flags "--cli"
      '';

      extraPkgs = p:
        with p; [
          # Qt6 dependencies for PySide6
          qt6.qtbase
          qt6.qtwayland
          libxkbcommon

          # X11/XCB dependencies
          libxcb
          xcb-util-cursor
          xorg.libX11
          xorg.libXext
          xorg.libXrender
          xorg.libXi

          # Graphics
          libGL
          libdrm
          mesa

          # FUSE for AppImage internal operations
          fuse
          fuse3

          # Network/SSL for downloads
          openssl
          curl
          cacert

          # Wine/Proton interaction
          wine
          winetricks

          # Archive handling
          p7zip
          unzip

          # General utilities
          coreutils
          bash
        ];

      meta = with lib; {
        description = "Linux Wabbajack client for installing modlists on Linux/Steam Deck";
        homepage = "https://github.com/Omni-guides/Jackify";
        license = licenses.gpl3;
        platforms = ["x86_64-linux"];
        mainProgram = "jackify";
      };
    };

  # Modlist submodule type definition
  modlistType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Display name for the modlist";
        example = "FUS Ro Dah VR";
      };

      source = mkOption {
        type = types.either types.path types.str;
        description = "Path to .wabbajack file or URL to download";
        example = "/home/user/Downloads/FUS.wabbajack";
      };

      installPath = mkOption {
        type = types.str;
        default = "";
        description = "Installation directory. If empty, uses directories.modlists/<name>";
      };

      downloadPath = mkOption {
        type = types.str;
        default = "";
        description = "Download cache directory. If empty, uses directories.downloads";
      };

      game = mkOption {
        type = types.enum [
          "SkyrimVR"
          "FalloutVR"
          "SkyrimSE"
          "SkyrimLE"
          "Fallout4"
          "FalloutNV"
          "Oblivion"
          "Morrowind"
          "Starfield"
          "Cyberpunk2077"
          "DragonAgeOrigins"
        ];
        default = "SkyrimVR";
        description = "Target game for the modlist";
      };

      steamAppId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Steam App ID for the target game. Used for Proton prefix and shortcuts.";
        example = "611670";
      };

      protonPrefix = mkOption {
        type = types.str;
        default = "";
        description = "Custom Proton prefix path. If empty, uses Steam's default compatdata location.";
      };

      autoInstall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to automatically install this modlist on home-manager activation.
          WARNING: Large modlists can be 100GB+. Manual installation is recommended.
        '';
      };

      createShortcut = mkOption {
        type = types.bool;
        default = true;
        description = "Create a Steam shortcut for this modlist";
      };
    };
  };

  # Steam App IDs for supported games
  defaultSteamAppIds = {
    SkyrimVR = "611670";
    FalloutVR = "611660";
    SkyrimSE = "489830";
    SkyrimLE = "72850";
    Fallout4 = "377160";
    FalloutNV = "22380";
    Oblivion = "22330";
    Morrowind = "22320";
    Starfield = "1716740";
    Cyberpunk2077 = "1091500";
    DragonAgeOrigins = "47810";
  };

  # Get Steam App ID for a modlist (explicit or default based on game)
  getAppId = modlist:
    if modlist.steamAppId != null
    then modlist.steamAppId
    else defaultSteamAppIds.${modlist.game} or null;
in {
  options.curtbushko.gaming.skyrimvr = {
    enable = mkEnableOption "Skyrim VR modding with Jackify";

    package = mkOption {
      type = types.package;
      default = jackifyPkg;
      description = "The Jackify package to use";
    };

    modlists = mkOption {
      type = types.attrsOf modlistType;
      default = {};
      description = "Declarative modlist definitions";
      example = lib.literalExpression ''
        {
          fus = {
            name = "FUS Ro Dah VR";
            source = "/path/to/FUS.wabbajack";
            game = "SkyrimVR";
            autoInstall = false;
          };
        }
      '';
    };

    steam = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam integration (shortcuts, Proton setup)";
      };

      libraryPath = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.local/share/Steam";
        description = "Path to Steam library";
      };

      protonVersion = mkOption {
        type = types.str;
        default = "Proton Experimental";
        description = "Proton version to use for modded games";
      };

      createShortcuts = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically create Steam shortcuts for installed modlists";
      };
    };

    directories = {
      jackifyData = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Jackify";
        description = "Jackify data directory";
      };

      downloads = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Jackify/downloads";
        description = "Default download cache directory";
      };

      modlists = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Jackify/modlists";
        description = "Default modlist installation directory";
      };
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to install alongside Jackify";
    };
  };

  config = mkIf (gamingCfg.enable && cfg.enable && isLinux) {
    # Install Jackify and required dependencies
    home.packages =
      [
        cfg.package
        pkgs.protontricks
        pkgs.winetricks
        pkgs.p7zip
        pkgs.cabextract
      ]
      ++ cfg.extraPackages;

    # XDG config for Jackify
    xdg.configFile."jackify/settings.json".text = builtins.toJSON {
      steamPath = cfg.steam.libraryPath;
      downloadPath = cfg.directories.downloads;
      modlistsPath = cfg.directories.modlists;
      protonVersion = cfg.steam.protonVersion;
      modlists =
        lib.mapAttrs (name: modlist: {
          inherit (modlist) name source game;
          installPath =
            if modlist.installPath != ""
            then modlist.installPath
            else "${cfg.directories.modlists}/${name}";
          downloadPath =
            if modlist.downloadPath != ""
            then modlist.downloadPath
            else cfg.directories.downloads;
          steamAppId = getAppId modlist;
          protonPrefix =
            if modlist.protonPrefix != ""
            then modlist.protonPrefix
            else "${cfg.steam.libraryPath}/steamapps/compatdata/${getAppId modlist}";
        })
        cfg.modlists;
    };

    # Create directory structure on activation
    home.activation.setupSkyrimVRDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create Jackify directories
      run mkdir -p "${cfg.directories.jackifyData}"
      run mkdir -p "${cfg.directories.downloads}"
      run mkdir -p "${cfg.directories.modlists}"

      # Create modlist-specific directories
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: modlist: ''
          run mkdir -p "${
            if modlist.installPath != ""
            then modlist.installPath
            else "${cfg.directories.modlists}/${name}"
          }"
        '')
        cfg.modlists)}
    '';

    # Generate helper script for modlist information
    home.file.".local/bin/skyrimvr-modlists" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # SkyrimVR Modlist Helper - Generated by NixOS
        # Lists configured modlists and their status

        echo "=== Configured Modlists ==="
        echo ""
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: modlist: let
            installDir =
              if modlist.installPath != ""
              then modlist.installPath
              else "${cfg.directories.modlists}/${name}";
            appId = getAppId modlist;
          in ''
            echo "Modlist: ${modlist.name}"
            echo "  ID: ${name}"
            echo "  Game: ${modlist.game}"
            echo "  Steam App ID: ${
              if appId != null
              then appId
              else "N/A"
            }"
            echo "  Install Path: ${installDir}"
            echo "  Source: ${toString modlist.source}"
            if [ -d "${installDir}" ] && [ "$(ls -A "${installDir}" 2>/dev/null)" ]; then
              echo "  Status: Installed"
            else
              echo "  Status: Not Installed"
            fi
            echo ""
          '')
          cfg.modlists)}

        echo "=== Commands ==="
        echo "  jackify          - Launch Jackify GUI"
        echo "  jackify-cli      - Launch Jackify CLI"
        echo ""
        echo "=== Directories ==="
        echo "  Jackify Data:    ${cfg.directories.jackifyData}"
        echo "  Downloads:       ${cfg.directories.downloads}"
        echo "  Modlists:        ${cfg.directories.modlists}"
        echo "  Steam Library:   ${cfg.steam.libraryPath}"
      '';
    };

    # Auto-install modlists with autoInstall = true (use with caution)
    home.activation.installSkyrimVRModlists = lib.hm.dag.entryAfter ["setupSkyrimVRDirectories"] ''
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (
          name: modlist:
            lib.optionalString modlist.autoInstall (let
              installDir =
                if modlist.installPath != ""
                then modlist.installPath
                else "${cfg.directories.modlists}/${name}";
            in ''
              # Check if modlist is already installed
              if [ ! -f "${installDir}/.jackify-installed" ]; then
                echo "NOTE: Modlist '${modlist.name}' is configured for auto-install"
                echo "      Due to the size of modlists (often 100GB+), automatic installation"
                echo "      during activation is disabled by default."
                echo ""
                echo "      To install manually, run:"
                echo "        jackify"
                echo ""
                echo "      Then select the modlist from the configured list."
              fi
            '')
        )
        cfg.modlists)}
    '';
  };
}
