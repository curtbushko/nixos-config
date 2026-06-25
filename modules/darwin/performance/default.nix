{
  config,
  lib,
  pkgs,
  ...
}: {
  # macOS Performance Optimization
  # Disables unnecessary background services to reduce CPU usage and heat
  #
  # Services disabled based on user preferences:
  # - Intelligence: Siri, suggestd, intelligence platform
  # - Continuity: Handoff, Universal Control (keeps AirDrop)
  # - Apps: Game Center, Safari bookmark sync
  # - Media: Reduces background media analysis

  system.defaults.NSGlobalDomain = {
    # Disable automatic text substitutions (reduces background processing)
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
  };

  system.defaults.dock = {
    # Disable recent apps in dock
    show-recents = false;
    # Disable Dashboard
    dashboard-in-overlay = false;
  };

  system.defaults.finder = {
    # Disable search for suggestions
    FXEnableExtensionChangeWarning = false;
  };

  # Use CustomUserPreferences for settings that don't have dedicated nix-darwin options
  # This is the declarative way to set macOS preferences (better than defaults write in scripts)
  system.defaults.CustomUserPreferences = {
    # Disable Siri completely
    "com.apple.Siri" = {
      StatusMenuVisible = false;
      UserHasDeclinedEnable = true;
    };
    "com.apple.assistant.support" = {
      "Assistant Enabled" = 0;
      "Search Queries Data Sharing Status" = 2; # Disable search queries data sharing
    };

    # Disable Apple Intelligence features and opt-out
    "com.apple.CloudSubscriptionFeatures.optIn" = {
      "545129924" = false;   # Apple Intelligence feature flag
      "1341174415" = false;  # Apple Intelligence feature flag
      "device" = false;      # Device-level opt-in
      "auto_opt_in" = false; # Automatic opt-in
    };
    "com.apple.AppleIntelligenceReport" = {
      reportDuration = 0; # Disable intelligence reporting
    };

    # Disable Spotlight AI suggestions
    "com.apple.Spotlight" = {
      SiriSuggestionsEnabled = false;
    };

    # Disable Siri app access, learning, and App Clips
    # Note: With Siri fully disabled above, this prevents any remaining suggestion services
    "com.apple.suggestions" = {
      SuggestionsLearnFromAppClips = 0;  # Don't learn from App Clips
      SuggestionsSuggestAppClips = 0;    # Don't suggest App Clips
      # SiriCanLearnFromAppBlacklist controls per-app learning (managed by system settings)
      # AppCanShowSiriSuggestionsBlacklist controls per-app suggestions display
    };

    # Disable advertising and analytics
    "com.apple.AdLib" = {
      forceLimitAdTracking = 1;
      allowApplePersonalizedAdvertising = 0;
      allowIdentifierForAdvertising = 0;
    };

    # Disable crash reporter dialogs (reduces background activity)
    "com.apple.CrashReporter" = {
      DialogType = "none";
    };

    # Disable Safari Universal Search (web search from address bar)
    "com.apple.safari" = {
      UniversalSearchEnabled = 0;
    };
  };

  # Disable services via launchctl
  system.activationScripts.postActivation.text = ''
    # Get the current user (console owner)
    CURRENT_USER=$(/usr/bin/stat -f %Su /dev/console)
    USER_UID=$(/usr/bin/id -u "$CURRENT_USER")

    # ========================================================================
    # INTELLIGENCE & AI SERVICES
    # ========================================================================
    # Siri services - disable in all domains (gui, user, system) for defense-in-depth
    # GUI domain (primary)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.assistantd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.assistant_service" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.siriactionsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.siriappintentsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.siriinferenced" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.siriknowledged" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.sirittsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.SiriTTSTrainingAgent" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.siri.context.service" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.Siri.agent" 2>/dev/null || true

    # User domain (defensive - may not exist but disable anyway)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "user/$USER_UID/com.apple.assistantd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "user/$USER_UID/com.apple.Siri.agent" 2>/dev/null || true

    # System domain (requires root)
    /usr/bin/sudo /bin/launchctl disable "system/com.apple.assistantd" 2>/dev/null || true
    /usr/bin/sudo /bin/launchctl disable "system/com.apple.Siri.agent" 2>/dev/null || true
    /usr/bin/sudo /bin/launchctl disable "system/com.apple.siri.acousticsignature" 2>/dev/null || true

    # Intelligence platform
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligencecontextd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligenceflowd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligenceplatformd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligencetasksd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligentroutingd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.visualintelligenced" 2>/dev/null || true

    # Suggestions and predictions
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.suggestd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.proactived" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.proactiveeventtrackerd" 2>/dev/null || true

    # Knowledge and context
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.knowledge-agent" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.knowledgeconstructiond" 2>/dev/null || true

    # Spotlight knowledge services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.spotlightknowledged" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.spotlightknowledged.updater" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.spotlightknowledged.importer" 2>/dev/null || true

    # Also unload plists (secondary approach for persistence)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.Siri.agent.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.siriactionsd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.siriappintentsd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.siriinferenced.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.siriknowledged.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.sirittsd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.SiriTTSTrainingAgent.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.intelligencecontextd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.intelligenceflowd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.intelligenceplatformd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.intelligencetasksd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.photoanalysisd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.visualintelligenced.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.spotlightknowledged.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.spotlightknowledged.updater.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.spotlightknowledged.importer.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.SoftwareUpdateNotificationManager.plist 2>/dev/null || true

    # Kill running processes immediately
    /usr/bin/killall -9 assistantd assistant_service siriactionsd siriappintentsd siriinferenced siriknowledged sirittsd SiriTTSTrainingAgent 2>/dev/null || true
    /usr/bin/killall -9 intelligencecontextd intelligenceflowd intelligenceplatformd intelligencetasksd intelligentroutingd visualintelligenced 2>/dev/null || true
    /usr/bin/killall -9 knowledgeconstructiond IntelligencePlatformComputeService AppleIntelligenceReportingProcessingService 2>/dev/null || true
    /usr/bin/killall -9 suggestd proactived proactiveeventtrackerd 2>/dev/null || true
    /usr/bin/killall -9 spotlightknowledged.updater spotlightknowledged.importer 2>/dev/null || true

    # ========================================================================
    # CONTINUITY SERVICES (Handoff, Universal Control)
    # ========================================================================
    # Handoff
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.coreservices.useractivityd" 2>/dev/null || true

    # Universal Control (keep AirDrop/sharingd)
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.universalcontrol FeatureFlag -bool false 2>/dev/null || true

    # ========================================================================
    # SAFARI SYNC
    # ========================================================================
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.SafariBookmarksSyncAgent" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.SafariHistoryServiceAgent" 2>/dev/null || true

    # ========================================================================
    # GAME CENTER
    # ========================================================================
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.gamed" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.gamesaved" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.GameController.gamecontrolleragentd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.GameOverlayUI" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.GamePolicyAgent" 2>/dev/null || true

    # ========================================================================
    # MAPS SERVICES
    # ========================================================================
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.maps.mapspushd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.maps.mapssyncd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.Maps.destinationd" 2>/dev/null || true
    /usr/bin/killall -9 mapspushd mapssyncd 2>/dev/null || true

    # ========================================================================
    # ADDITIONAL CPU-INTENSIVE SERVICES
    # ========================================================================
    # Photo analysis (high CPU usage)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.photoanalysisd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.mediaanalysisd" 2>/dev/null || true
    /usr/bin/killall -9 photoanalysisd mediaanalysisd 2>/dev/null || true
    /usr/bin/killall -9 SoftwareUpdateNotificationManager 2>/dev/null || true

    # News and content suggestions
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.newsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.ap.promotedcontentd" 2>/dev/null || true

    # Podcasts and media
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.podcasts.PodcastContentService" 2>/dev/null || true

    # App Store background updates
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.appstoreagent" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.commerce" 2>/dev/null || true

    # Software update notifications
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.SoftwareUpdateNotificationManager" 2>/dev/null || true

    # Shazam
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.shazamd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.shazameventsd" 2>/dev/null || true

    # Screen Time tracking
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.ScreenTimeAgent" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.UsageTrackingAgent" 2>/dev/null || true

    # Generative AI features
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.generativeexperiencesd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.imageplaygroundd" 2>/dev/null || true

  '';
}
