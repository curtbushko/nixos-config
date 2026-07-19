{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.wm.supercmd;
  isDarwin = pkgs.stdenv.isDarwin;

  # Config-only settings. Runtime state (recentCommands,
  # recentCommandLaunchCounts, rootSearchRanking) is intentionally omitted so
  # SuperCmd can keep updating frecency data without fighting Nix.
  #
  # SuperCmd atomic-writes settings.json, which replaces the home-manager
  # symlink with a real file on any GUI change. `home-manager switch` (via
  # `task switch`) restores the symlink and snaps the file back to what's
  # declared here — so make changes in this file, not the GUI.
  settings = {
    globalShortcut = "Command+Space";
    openAtLogin = true;

    disabledCommands = [
      "system-cursor-prompt"
      "system-add-to-memory"
      "system-clipboard-manager"
      "system-emoji-picker"
      "system-reset-launcher-position"
      "system-open-ai-settings"
      "system-supercmd-whisper"
      "system-supercmd-speak"
      "system-menu-item-search"
      "system-window-management"
      "system-window-management-left"
      "system-window-management-right"
      "system-window-management-top"
      "system-window-management-bottom"
      "system-window-management-center"
      "system-window-management-center-80"
      "system-window-management-fill"
      "system-window-management-maximize-width"
      "system-window-management-maximize-height"
      "system-window-management-top-left"
      "system-window-management-top-right"
      "system-window-management-bottom-left"
      "system-window-management-bottom-right"
      "system-window-management-first-third"
      "system-window-management-center-third"
      "system-window-management-last-third"
      "system-window-management-first-two-thirds"
      "system-window-management-center-two-thirds"
      "system-window-management-last-two-thirds"
      "system-window-management-first-fourth"
      "system-window-management-second-fourth"
      "system-window-management-third-fourth"
      "system-window-management-last-fourth"
      "system-window-management-first-three-fourths"
      "system-window-management-center-three-fourths"
      "system-window-management-last-three-fourths"
      "system-window-management-top-left-sixth"
      "system-window-management-top-center-sixth"
      "system-window-management-top-right-sixth"
      "system-window-management-bottom-left-sixth"
      "system-window-management-bottom-center-sixth"
      "system-window-management-bottom-right-sixth"
      "system-window-management-increase-size-10"
      "system-window-management-decrease-size-10"
      "system-window-management-increase-left-10"
      "system-window-management-increase-right-10"
      "system-window-management-increase-top-10"
      "system-window-management-increase-bottom-10"
      "system-window-management-decrease-left-10"
      "system-window-management-decrease-right-10"
      "system-window-management-decrease-top-10"
      "system-window-management-decrease-bottom-10"
      "system-window-management-move-up-10"
      "system-window-management-move-down-10"
      "system-window-management-move-left-10"
      "system-window-management-move-right-10"
      "system-open-extensions-settings"
      "system-open-extension-store"
      "system-open-onboarding"
      "system-quit-launcher"
      "system-create-snippet"
      "system-search-snippets"
      "system-search-notes"
      "system-create-note"
      "system-search-canvases"
      "system-create-canvas"
      "system-create-quicklink"
      "system-search-quicklinks"
      "system-search-files"
      "system-search-web"
      "system-search-open-tabs"
      "system-search-bookmarks"
      "system-search-history"
      "system-my-schedule"
      "system-camera"
      "system-create-script-command"
      "system-open-script-commands"
      "system-import-snippets"
      "system-export-snippets"
      "system-check-for-updates"
      "system-close-all-apps"
      "system-sleep"
      "system-restart"
      "system-lock-screen"
      "system-logout"
      "system-empty-trash"
      "system-toggle-appearance"
      "system-shutdown"
      "app-adblock-plus"
      "app-alacritty-8341fb3f"
      "app-alacritty"
      "app-app-store"
      "app-apps"
      "app-archive-utility"
      "app-audio-midi-setup"
      "app-automator"
      "app-baldur-s-gate-3"
      "app-bluetooth-file-exchange"
      "app-books"
      "app-calendar"
      "app-campo"
      "app-chess"
      "app-claude"
      "app-clock"
      "app-colorsync-utility"
      "app-console"
      "app-contacts"
      "app-desk-view"
      "app-dictionary"
      "app-digital-color-meter"
      "app-directory-utility"
      "app-disk-utility"
      "app-dvd-player"
      "app-expansion-slot-utility"
      "app-feedback-assistant"
      "app-feedback-assistant-1261b173"
      "app-finder"
      "app-findmy"
      "app-firefox-2a1effef"
      "app-folder-actions-setup"
      "app-font-book"
      "app-freeform"
      "app-games"
      "app-garageband"
      "app-google-chrome"
      "app-grapher"
      "app-home"
      "app-image-capture"
      "app-image-playground"
      "app-imovie"
      "app-ios-app-installer"
      "app-iphone-mirroring"
      "app-journal"
      "app-keynote"
      "app-magnifier"
      "app-mail"
      "app-maps"
      "app-migration-assistant"
      "app-mission-control"
      "app-mpv"
      "app-mpv-cbc99328"
      "app-music"
      "app-news"
      "app-notes"
      "app-notunes"
      "app-numbers"
      "app-obs"
      "app-openchamber"
      "app-openmtp"
      "app-pages"
      "app-passwords"
      "app-phone"
      "app-photo-booth"
      "app-photos"
      "app-preview"
      "app-print-center"
      "app-qrookie"
      "app-quicktime-player"
      "app-reminders"
      "app-save-to-raindrop-io"
      "app-screen-sharing"
      "app-screenshot"
      "app-script-editor"
      "app-shortcuts"
      "app-sidequest"
      "app-siri"
      "app-stickies"
      "app-stocks"
      "app-supercmd"
      "app-system-information"
      "app-terminal"
      "app-textedit"
      "app-ticket-viewer"
      "app-time-machine"
      "app-tips"
      "app-transmission"
      "app-tv"
      "app-unwatched"
      "app-voicememos"
      "app-voiceover-utility"
      "app-weather"
      "app-wireless-diagnostics"
      "app-prismlauncher-becdb66a"
      "settings-about"
      "settings-accessibility"
      "settings-air-drop-continuity"
      "settings-appearance"
      "settings-apple-account"
      "settings-apple-care-warranty"
      "settings-apple-id-pref-pane"
      "settings-background-security-improvements"
      "settings-battery"
      "settings-bluetooth"
      "settings-c-ds-dv-ds"
      "settings-class-kit-preference-pane"
      "settings-class-progress"
      "settings-classroom"
      "settings-date-time"
      "settings-desktop-dock"
      "settings-desktop-screen-effects"
      "settings-device-management"
      "settings-displays"
      "settings-dock-menu-bar"
      "settings-energy-saver"
      "settings-expose"
      "settings-extensions"
      "settings-family"
      "settings-family-sharing-pref-pane"
      "settings-focus"
      "settings-follow-ups"
      "settings-game-centre"
      "settings-game-controllers"
      "settings-general"
      "settings-headphone"
      "settings-home"
      "settings-internet-accounts"
      "settings-keyboard"
      "settings-language-region"
      "settings-localization"
      "settings-lock-screen"
      "settings-login-items"
      "settings-menu-bar"
      "settings-mouse"
      "settings-network"
      "settings-notifications"
      "settings-passwords"
      "settings-power-preferences"
      "settings-print-and-fax"
      "settings-print-and-scan"
      "settings-printers-scanners"
      "settings-privacy-security"
      "settings-profiles"
      "settings-screen-time"
      "settings-security"
      "settings-sharing"
      "settings-siri"
      "settings-software-update"
      "settings-sound"
      "settings-speech"
      "settings-spotlight"
      "settings-startup-disk"
      "settings-storage"
      "settings-time-machine"
      "settings-touch-id"
      "settings-touch-id-password"
      "settings-trackpad"
      "settings-transfer-or-reset"
      "settings-users-groups"
      "settings-vpn"
      "settings-wallet"
      "settings-wallet-apple-pay"
      "settings-wallpaper"
      "settings-wi-fi"
    ];

    enabledCommands = [
      "app-about-this-mac"
      "app-activity-monitor"
      "app-bitwarden"
      "app-calculator"
      "app-discord"
      "app-draw-io"
      "app-facetime"
      "app-firefox"
      "app-ghostty"
      "app-keychain-access"
      "app-messages"
      "app-obsidian"
      "app-podcasts"
      "app-prismlauncher"
      "app-rectangle"
      "app-safari"
      "app-slack"
      "app-steam"
      "app-system-settings"
      "system-open-settings"
      "app-vlc"
      "app-whatsapp"
      "app-zoom-us"
    ];

    searchApplicationsScope = [
      "/Applications"
      "/Applications/Utilities"
      "/System/Applications"
      "/System/Applications/Utilities"
      "/System/Library/CoreServices/Applications"
      "/Users/curtbushko/Applications"
      "/Applications/Nix Apps"
    ];

    scriptCommandFolders = [];

    commandHotkeys = {
      "system-supercmd-whisper" = "Command+Shift+W";
      "system-supercmd-whisper-speak-toggle" = "Fn";
      "system-supercmd-speak" = "Command+Shift+S";
      "system-window-management-left" = "Control+Alt+Left";
      "system-window-management-right" = "Control+Alt+Right";
      "system-window-management-top" = "Control+Alt+Up";
      "system-window-management-bottom" = "Control+Alt+Down";
      "system-window-management-top-left" = "Control+Alt+U";
      "system-window-management-top-right" = "Control+Alt+I";
      "system-window-management-bottom-left" = "Control+Alt+J";
      "system-window-management-bottom-right" = "Control+Alt+K";
      "system-window-management-first-third" = "Control+Alt+D";
      "system-window-management-center-third" = "Control+Alt+F";
      "system-window-management-last-third" = "Control+Alt+G";
      "system-window-management-first-two-thirds" = "Control+Alt+E";
      "system-window-management-center-two-thirds" = "Control+Alt+R";
      "system-window-management-last-two-thirds" = "Control+Alt+T";
      "system-window-management-center" = "Control+Alt+C";
      "system-window-management-fill" = "Control+Alt+Return";
      "system-window-management-increase-size-10" = "Control+Alt+=";
      "system-window-management-decrease-size-10" = "Control+Alt+-";
    };

    commandAliases = {};
    pinnedCommands = ["system-open-settings"];

    hasSeenOnboarding = true;
    hasSeenWhisperOnboarding = true;
    disableFileSearchResults = true;
    showMenuBarIcon = true;

    ai = {
      provider = "openai";
      openaiApiKey = "";
      anthropicApiKey = "";
      geminiApiKey = "";
      elevenlabsApiKey = "";
      mistralApiKey = "";
      supermemoryApiKey = "";
      supermemoryClient = "";
      supermemoryBaseUrl = "https://api.supermemory.ai";
      supermemoryLocalMode = false;
      ollamaBaseUrl = "http://localhost:11434";
      defaultModel = "";
      speechCorrectionModel = "";
      speechToTextModel = "whispercpp";
      speechLanguage = "en-US";
      speechVocabulary = "";
      textToSpeechModel = "edge-tts";
      edgeTtsVoice = "en-US-EricNeural";
      speechCorrectionEnabled = false;
      enabled = false;
      llmEnabled = true;
      whisperEnabled = true;
      readEnabled = true;
      openaiCompatibleAppendV1 = true;
      openaiCompatibleBaseUrl = "";
      openaiCompatibleApiKey = "";
      openaiCompatibleModel = "";
      lmStudioBaseUrl = "http://127.0.0.1:1234/v1";
      lmStudioModel = "";
      lmStudioApiKey = "";
    };

    debugMode = false;
    appLanguage = "system";
    fontSize = "medium";
    uiStyle = "default";
    baseColor = "#101113";
    launcherBackgroundImageEverywhere = false;
    launcherBackgroundImageBlurPercent = 25;
    launcherBackgroundImageOpacityPercent = 45;

    hyperKey = {
      enabled = false;
      sourceKey = "caps-lock";
      capsLockTapBehavior = "nothing";
    };

    launcherViewMode = "compact";
    navigationStyle = "vim";
    clipboardHistoryRetentionDays = null;
    clipboardAppBlacklist = [];
    emojiPickerEnabled = true;
    emojiPickerTriggerPrefix = ":";
    emojiPickerExcludedAppBundleIds = [];

    browserSearch = {
      enabled = false;
      alphaChromiumRootSearchEnabled = false;
      historyRetentionDays = 90;
      profileSourceIds = [];
      profiles = [];
      profileFilters = {};
      resultLimitPerGroup = 2;
      resultGroups = [
        {
          kind = "bookmark";
          limit = 2;
        }
        {
          kind = "open-tab";
          limit = 2;
        }
        {
          kind = "history";
          limit = 2;
        }
      ];
      nicknames = [];
      webSearchDefaultBangKey = "g";
      webSearchBangOverrides = [];
      webSearchBangUsage = {};
      webSearchDisabledBangKeys = [];
      webSearchBangCustomProviders = [];
      webSearchShowHiddenBangs = false;
      webSearchSuggestionsEnabled = true;
    };

    rootSearchAutocompleteEnabled = true;
    popToRootSearchTimeoutSeconds = 90;
    installedExtensions = [];
    extensionUninstallTombstones = {};
    extensionPreferences = {};
    extensionCommandPreferences = {};
    extensionCommandArguments = {};
    autoQuitApps = [];
    autoQuitDefaultTimeoutSeconds = 180;
  };
in {
  options.ns.wm.supercmd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to manage the SuperCmd settings.json declaratively";
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    home.file."Library/Application Support/SuperCmd/settings.json" = {
      text = builtins.toJSON settings;
      force = true;
    };
  };
}
