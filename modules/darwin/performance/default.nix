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

    # ========================================================================
    # APPLE INTELLIGENCE - COMPREHENSIVE DISABLE
    # ========================================================================

    # Disable Apple Intelligence feature flags and opt-out
    "com.apple.CloudSubscriptionFeatures.optIn" = {
      "545129924" = false;    # Apple Intelligence feature flag
      "1341174415" = false;   # Apple Intelligence feature flag
      "device" = false;       # Device-level opt-in
      "auto_opt_in" = false;  # Automatic opt-in
    };

    # Disable Apple Intelligence reporting
    "com.apple.AppleIntelligenceReport" = {
      reportDuration = 0;
      ReportingEnabled = false;
    };

    # Disable Apple Intelligence core settings
    "com.apple.AppleIntelligence" = {
      AppleIntelligenceEnabled = false;
      WritingToolsEnabled = false;
      SummarizationEnabled = false;
      ProofreadingEnabled = false;
      RewriteEnabled = false;
      SmartReplyEnabled = false;
      ImagePlaygroundEnabled = false;
      GenmojisEnabled = false;
      VisualIntelligenceEnabled = false;
      PrioritizeNotificationsEnabled = false;
      ReduceInterruptionsEnabled = false;
    };

    # Disable Writing Tools specifically
    "com.apple.WritingTools" = {
      WritingToolsEnabled = false;
      ProofreadEnabled = false;
      RewriteEnabled = false;
      SummarizeEnabled = false;
      ComposeEnabled = false;
      SmartReplyEnabled = false;
    };

    # Disable Image Playground and Genmoji
    "com.apple.ImagePlayground" = {
      Enabled = false;
      ImagePlaygroundEnabled = false;
    };
    "com.apple.Genmoji" = {
      Enabled = false;
      GenmojisEnabled = false;
    };

    # Disable Visual Intelligence (camera AI features)
    "com.apple.VisualIntelligence" = {
      Enabled = false;
      VisualIntelligenceEnabled = false;
    };

    # Disable notification prioritization AI
    "com.apple.notificationcenter" = {
      IntelligentBreakthroughEnabled = false;
      PrioritizeNotificationsEnabled = false;
      SummarizeNotificationsEnabled = false;
    };

    # Disable mail AI features
    "com.apple.mail" = {
      IntelligentMailEnabled = false;
      SmartReplyEnabled = false;
      SummarizationEnabled = false;
      PrioritySenderEnabled = false;
    };

    # Disable messages AI features
    "com.apple.MobileSMS" = {
      SmartReplyEnabled = false;
      IntelligentSuggestionsEnabled = false;
    };

    # Disable Photos AI features
    "com.apple.Photos" = {
      IntelligentSearchEnabled = false;
      MemoryCreationEnabled = false;
      CleanUpToolEnabled = false;
    };

    # Disable Notes AI features
    "com.apple.Notes" = {
      SmartFoldersEnabled = false;
      TranscriptionSummaryEnabled = false;
      IntelligentSearchEnabled = false;
    };

    # Disable Safari AI features
    "com.apple.Safari" = {
      IntelligentTrackingPreventionEnabled = false;
      WebPageSummarizationEnabled = false;
      HighlightsEnabled = false;
    };

    # Disable generative experiences daemon
    "com.apple.generativeexperiences" = {
      Enabled = false;
    };

    # Disable private cloud compute
    "com.apple.privatecomputecore" = {
      Enabled = false;
      PrivateCloudComputeEnabled = false;
    };

    # Disable Spotlight AI suggestions
    "com.apple.Spotlight" = {
      SiriSuggestionsEnabled = false;
      IntelligentSearchEnabled = false;
    };

    # Disable Siri app access, learning, and suggestions globally
    # These settings disable per-app Siri access that appears in System Settings > Siri
    "com.apple.suggestions" = {
      # Global toggles - disable for ALL apps (no per-app blacklist needed)
      SiriCanLearnFromApp = false;           # Disable "Learn from this App" for all apps
      AppCanShowSiriSuggestions = false;     # Disable "Show Siri Suggestions" for all apps
      SuggestionsAllowGeoLocation = false;   # Disable location-based suggestions
      SuggestionsAllowNotificationAccess = false;  # Disable notification access for suggestions
      SuggestionsLearnFromAppClips = 0;      # Don't learn from App Clips
      SuggestionsSuggestAppClips = 0;        # Don't suggest App Clips
      SuggestionsAppLaunchLearningEnabled = false;  # Disable app launch learning
    };

    # Disable Siri search suggestions and Look Up
    "com.apple.lookup" = {
      LookupSuggestionsDisabled = true;      # Disable Look Up suggestions
    };

    # Disable Siri data syncing
    "com.apple.assistant.backedup" = {
      "Siri Data Sharing Opt-In Status" = 2;  # Opt out of Siri data sharing
      "Cloud Sync Enabled" = false;           # Disable Siri cloud sync
    };

    # Disable parsec (Siri suggestion engine)
    "com.apple.parsec" = {
      ParsecLocalModelDisabled = true;        # Disable local Siri model
    };

    # Disable search suggestions in Spotlight and Safari
    "com.apple.Safari.SandboxBroker" = {
      ShowSiriSuggestionsPreference = false;  # Disable Siri suggestions in Safari
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
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.SiriAUSP" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.SiriSuggestionsBookkeepingService" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.siri.embeddedspeech" 2>/dev/null || true

    # User domain (defensive - may not exist but disable anyway)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "user/$USER_UID/com.apple.assistantd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "user/$USER_UID/com.apple.Siri.agent" 2>/dev/null || true

    # System domain (requires root)
    /usr/bin/sudo /bin/launchctl disable "system/com.apple.assistantd" 2>/dev/null || true
    /usr/bin/sudo /bin/launchctl disable "system/com.apple.Siri.agent" 2>/dev/null || true
    /usr/bin/sudo /bin/launchctl disable "system/com.apple.siri.acousticsignature" 2>/dev/null || true

    # AGGRESSIVE: Use bootout to forcefully remove services from launchd
    # bootout is more aggressive than disable - it removes the service entirely
    # Note: These may fail if service isn't loaded, which is fine
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.siriinferenced" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.sirittsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.siriknowledged" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.siriappintentsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.siriactionsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.assistantd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.assistant_service" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.Siri.agent" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.SiriTTSTrainingAgent" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.siri.context.service" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.SiriSuggestionsBookkeepingService" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.siri.embeddedspeech" 2>/dev/null || true

    # Intelligence platform - core services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligencecontextd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligenceflowd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligenceplatformd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligencetasksd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligentroutingd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.visualintelligenced" 2>/dev/null || true

    # Intelligence platform - additional services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligencemodeld" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.intelligenceindexd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.IntelligencePlatformComputeService" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.AppleIntelligenceReportingProcessingService" 2>/dev/null || true

    # Writing Tools and generative features
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.writingtoolsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.generativeexperiencesd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.gaborflowservice" 2>/dev/null || true

    # Image Playground and Genmoji
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.imageplaygroundd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.genmojid" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.ImagePlayground" 2>/dev/null || true

    # Private Cloud Compute
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.privatecomputecored" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.privatecomputecore" 2>/dev/null || true

    # Machine Learning services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.mlruntimed" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.mlhostd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.coreml.coremlcompilerd" 2>/dev/null || true

    # Natural Language processing
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.naturallanguaged" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.NaturalLanguage.LexiconService" 2>/dev/null || true

    # Semantic index (AI indexing)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.semanticindexd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.semanticimageworkerd" 2>/dev/null || true

    # Photo and media analysis (AI-powered)
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.photolibraryd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.photoanalysisd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.mediaanalysisd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.facedetectiond" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.videoanalysisagent" 2>/dev/null || true

    # Text and OCR services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.textrecognitiond" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.screencaptureagent" 2>/dev/null || true

    # Speech and transcription
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.SpeechRecognitionCore.speechrecognitiond" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.audio.SpeechSynthesisServer" 2>/dev/null || true

    # Translation services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.triald" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.translationd" 2>/dev/null || true

    # AGGRESSIVE: bootout intelligence services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.intelligencecontextd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.intelligenceflowd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.intelligenceplatformd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.intelligencetasksd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.intelligentroutingd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.visualintelligenced" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.intelligencemodeld" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.intelligenceindexd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.IntelligencePlatformComputeService" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.writingtoolsd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.generativeexperiencesd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.imageplaygroundd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.genmojid" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.suggestd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.proactived" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl bootout "gui/$USER_UID/com.apple.parsecd" 2>/dev/null || true

    # Suggestions and predictions
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.suggestd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.proactived" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.proactiveeventtrackerd" 2>/dev/null || true

    # Additional Siri suggestion services
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.parsecd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.parsec-fbf" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.routined" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.personaserver" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.biomesyncd" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.biomed" 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl disable "gui/$USER_UID/com.apple.coreduetd" 2>/dev/null || true

    # Disable per-app Siri suggestions via defaults (reinforces CustomUserPreferences)
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.suggestions SiriCanLearnFromApp -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.suggestions AppCanShowSiriSuggestions -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.suggestions SuggestionsAllowGeoLocation -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.Siri SiriPrefsContinuityEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.Siri LockscreenEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.Siri VoiceTriggerEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.Siri TypeToSiriEnabled -bool false 2>/dev/null || true

    # Disable Apple Intelligence via defaults (reinforces CustomUserPreferences)
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.AppleIntelligence AppleIntelligenceEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.AppleIntelligence WritingToolsEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.AppleIntelligence SummarizationEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.AppleIntelligence ImagePlaygroundEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.AppleIntelligence GenmojisEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.AppleIntelligence VisualIntelligenceEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.WritingTools WritingToolsEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.ImagePlayground Enabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.Genmoji Enabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.VisualIntelligence Enabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.generativeexperiences Enabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.privatecomputecore Enabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.notificationcenter IntelligentBreakthroughEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.notificationcenter SummarizeNotificationsEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.mail IntelligentMailEnabled -bool false 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /usr/bin/defaults write com.apple.mail SmartReplyEnabled -bool false 2>/dev/null || true

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
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.intelligentroutingd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.intelligencemodeld.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.intelligenceindexd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.writingtoolsd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.generativeexperiencesd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.imageplaygroundd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.genmojid.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.privatecomputecored.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.mlruntimed.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.mlhostd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.naturallanguaged.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.semanticindexd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.photoanalysisd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.mediaanalysisd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.visualintelligenced.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.textrecognitiond.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.translationd.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.spotlightknowledged.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.spotlightknowledged.updater.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.spotlightknowledged.importer.plist 2>/dev/null || true
    /usr/bin/sudo -u "$CURRENT_USER" /bin/launchctl unload -w /System/Library/LaunchAgents/com.apple.SoftwareUpdateNotificationManager.plist 2>/dev/null || true

    # Kill running processes immediately
    /usr/bin/killall -9 assistantd assistant_service siriactionsd siriappintentsd siriinferenced siriknowledged sirittsd SiriTTSTrainingAgent 2>/dev/null || true
    /usr/bin/killall -9 SiriAUSP SiriSuggestionsBookkeepingService siri.embeddedspeech 2>/dev/null || true
    /usr/bin/killall -9 intelligencecontextd intelligenceflowd intelligenceplatformd intelligencetasksd intelligentroutingd visualintelligenced 2>/dev/null || true
    /usr/bin/killall -9 intelligencemodeld intelligenceindexd IntelligencePlatformComputeService AppleIntelligenceReportingProcessingService 2>/dev/null || true
    /usr/bin/killall -9 knowledgeconstructiond knowledge-agent 2>/dev/null || true
    /usr/bin/killall -9 writingtoolsd generativeexperiencesd gaborflowservice 2>/dev/null || true
    /usr/bin/killall -9 imageplaygroundd genmojid ImagePlayground 2>/dev/null || true
    /usr/bin/killall -9 privatecomputecored mlruntimed mlhostd coremlcompilerd 2>/dev/null || true
    /usr/bin/killall -9 naturallanguaged semanticindexd semanticimageworkerd 2>/dev/null || true
    /usr/bin/killall -9 facedetectiond videoanalysisagent textrecognitiond 2>/dev/null || true
    /usr/bin/killall -9 speechrecognitiond SpeechSynthesisServer translationd triald 2>/dev/null || true
    /usr/bin/killall -9 suggestd proactived proactiveeventtrackerd 2>/dev/null || true
    /usr/bin/killall -9 parsecd routined personaserver biomesyncd biomed coreduetd 2>/dev/null || true
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
