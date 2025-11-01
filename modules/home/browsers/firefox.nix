{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.browsers;
in {
  config = mkIf cfg.enable {
    stylix.targets.firefox.profileNames = ["default"];
    programs.firefox = {
      enable = true;
      policies = {
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        DisableTelemetry = true;
        # to find the addon ID do:  about:debugging#/runtime/this-firefox
        #Extensions = {
        #  Locked = [
        #    # enable both extensions
        #    "uBlock0@raymondhill.net"
        #    "{446900e4-71c2-419f-a6a7-df9c091e268b}" # Extension ID for bitwarden
        #  ];
        #};
        ExtensionSettings = {
          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
        };
        Preferences = {
          "browser.in-content.dark-mode" = true; # Use dark mode
          "ui.systemUsesDarkTheme" = true;

          "extensions.autoDisableScopes" = 0; # Automatically enable extensions
          "extensions.update.enabled" = false;
        };
        Permissions = {
          Notifications = {
          Allow = [
            "https://web.whatsapp.com"
            "https://app.slack.com"
            "https://discord.com"
          ];
        };
    };
      };

      profiles.default = {
        id = 0;
        name = "default";
        extensions = {
          force = true;
          packages = with inputs.firefox-addons.packages.${pkgs.system}; [
            bitwarden
            ublock-origin
            vimium
            raindropio
          ];
          settings."uBlock0@raymondhill.net".settings = {
            selectedFilterLists = [
              "ublock-filters"
              "ublock-badware"
              "ublock-privacy"
              "ublock-unbreak"
              "ublock-quick-fixes"
            ];
          };
        };
        search.force = true;
        search.engines = {
          "Home Manager NixOs" = {
            urls = [
              {
                template = "https://mipmip.github.io/home-manager-option-search/";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["!hm"];
          };
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["!nixpkgs"];
          };
          "NixOS Wiki" = {
            urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
            icon = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = ["!nw"];
          };
          "Github Search" = {
            urls = [{template = "https://github.com/search?q={searchTerms}";}];
            icon = "https://github.githubassets.com/favicons/favicon.svg";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = ["!gh"];
          };
          google.metaData.alias = "@google";
          bing.metaData.hidden = true;
          amazondotcom-us.metaData.hidden = true;
          wikipedia.metaData.hidden = true;
        };
        settings = {
          # GENERAL
          "content.notify.interval" = 100000;
          "browser.startup.homepage" = "";
          "browser.toolbars.bookmarks.visibility" = "always";
          # KEYS (set Super instead of Ctrl)
          "ui.key.accelKey" = 91;
          # BOOKMARKS
          "browser.bookmarks.addedImportButton" = false;
          # GFX
          "gfx.canvas.accelerated" = true;
          "gfx.canvas.accelerated.cache-items" = 4096;
          "gfx.canvas.accelerated.cache-size" = 512;
          "gfx.content.skia-font-cache-size" = 20;
          "gfx.webrender.enabled" = true;
          "gfx.x11-egl.force-enabled" = true;
          # DISK
          "browser.cache.jsbc_compression_level" = 3;
          # MEDIA
          "media.av1.enabled" = false;
          "media.cache_readahead_limit" = 7200;
          "media.cache_resume_treshold" = 3600;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          "media.rdd-ffmpeg.enabled" = true;
          "media.memory_cache_max_size" = 65536;
          # IMAGE CACHE
          "image.mem.decode_bytes_at_a_time" = 32768;
          # NETWORK
          "network.buffer.cache.size" = 262144;
          "network.buffer.cache.count" = 128;
          "network.http.max-connections" = 1800;
          "network.http.max-persistent-connections-per-server" = 10;
          "network.http.max-urgent-start-excessive-connections-per-host" = 5;
          "network.http.pacing.requests.enabled" = false;
          "network.dnsCacheExpiration" = 3600;
          "network.dns.max_high_priority_threads" = 8;
          "network.ssl_tokens_cache_capacity" = 10240;
          # SPECULATIVE LOADING
          "network.dns.disablePrefetch" = true;
          "network.prefetch-next" = false;
          "network.predictor.enabled" = false;
          # EXPERIMENTAL
          "layout.css.grid-template-masonry-value.enabled" = true;
          "dom.enable_web_task_scheduling" = true;
          "layout.css.has-selector.enabled" = true;
          "dom.security.sanitizer.enabled" = true;
          # SECUREFOX
          # TRACKING PROTECTION
          "browser.contentblocking.category" = "strict";
          "urlclassifier.trackingSkipURLs" = "*.reddit.com, *.twitter.com, *.twimg.com, *.tiktok.com";
          "urlclassifier.features.socialtracking.skipURLs" = "*.instagram.com, *.twitter.com, *.twimg.com";
          "network.cookie.sameSite.noneRequiresSecure" = true;
          "browser.download.start_downloads_in_tmp_dir" = true;
          "browser.helperApps.deleteTempFileOnExit" = true;
          "browser.uitour.enabled" = false;
          "identity.fxaccounts.enabled" = false;
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.globalprivacycontrol.functionality.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          # OCSP & CERTS / HPKP
          "security.OCSP.enabled" = 0;
          "security.remote_settings.crlite_filters.enabled" = true;
          "security.pki.crlite_mode" = 2;
          # SSL / TLS
          "security.ssl.treat_unsafe_negotiation_as_broken" = true;
          "browser.xul.error_pages.expert_bad_cert" = true;
          "security.tls.enable_0rtt_data" = false;
          # DISK AVOIDANCE
          "browser.privatebrowsing.forceMediaMemoryCache" = true;
          "browser.sessionstore.interval" = 60000;
          # SHUTDOWN & SANITIZING
          "privacy.history.custom" = true;
          # SEARCH / URL BAR
          "browser.search.separatePrivateDefault.ui.enabled" = true;
          "browser.urlbar.update2.engineAliasRefresh" = true;
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.formfill.enable" = false;
          "security.insecure_connection_text.enabled" = true;
          "security.insecure_connection_text.pbmode.enabled" = true;
          "network.IDN_show_punycode" = true;
          # HTTPS-FIRST POLICY
          "dom.security.https_first" = true;
          # PASSWORDS
          "signon.rememberSignons" = false;
          "signon.formlessCapture.enabled" = false;
          "signon.privateBrowsingCapture.enabled" = false;
          "network.auth.subresource-http-auth-allow" = 1;
          "editor.truncate_user_pastes" = false;
          # ADDRESS + CREDIT CARD MANAGER
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          # MIXED CONTENT + CROSS-SITE
          "security.mixed_content.block_display_content" = true;
          "security.mixed_content.upgrade_display_content" = true;
          "security.mixed_content.upgrade_display_content.image" = true;
          "pdfjs.enableScripting" = false;
          "extensions.postDownloadThirdPartyPrompt" = false;
          # HEADERS / REFERERS
          "network.http.referer.XOriginTrimmingPolicy" = 2;
          # CONTAINERS
          "privacy.userContext.ui.enabled" = true;
          # WEBRTC
          "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
          "media.peerconnection.ice.default_address_only" = true;
          # SAFE BROWSING
          "browser.safebrowsing.downloads.remote.enabled" = false;
          # MOZILLA
          "permissions.default.desktop-notification" = 2;
          "permissions.default.geo" = 2;
          "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
          "permissions.manager.defaultsUrl" = "";
          "webchannel.allowObject.urlWhitelist" = "";
          # TELEMETRY
          "datareporting.policy.dataSubmissionEnabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";
          "browser.ping-centre.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          # EXPERIMENTS
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";
          # CRASH REPORTS
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          # DETECTION
          "captivedetect.canonicalURL" = "";
          "network.captive-portal-service.enabled" = false;
          "network.connectivity-service.enabled" = false;
          # PESKYFOX
          #  VPN/MOBILE PROMOS
          "browser.contentblocking.report.hide_vpn_banner" = true;
          "browser.contentblocking.report.mobile-ios.url" = "";
          "browser.contentblocking.report.mobile-android.url" = "";
          "browser.contentblocking.report.show_mobile_app" = false;
          "browser.contentblocking.report.vpn.enabled" = false;
          "browser.contentblocking.report.vpn.url" = "";
          "browser.contentblocking.report.vpn-promo.url" = "";
          "browser.contentblocking.report.vpn-android.url" = "";
          "browser.contentblocking.report.vpn-ios.url" = "";
          "browser.privatebrowsing.promoEnabled" = false;
          # MOZILLA UI
          "browser.privatebrowsing.vpnpromourl" = "";
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "browser.discovery.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "browser.preferences.moreFromMozilla" = false;
          "browser.tabs.tabmanager.enabled" = false;
          "browser.tabs.loadInBackground" = true;
          "browser.aboutConfig.showWarning" = false;
          "browser.aboutwelcome.enabled" = false;
          #DISABLE ONBOARDING 
          "browser.onboarding.newtour" = "performance,private,addons,customize,default";
          "browser.onboarding.updatetour" = "performance,library,singlesearch,customize";
          "browser.onboarding.enabled" = false;
          # THEME ADJUSTMENTS
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.compactmode.show" = true;
          "browser.display.focus_ring_on_anything" = true;
          "browser.display.focus_ring_style" = 0;
          "browser.display.focus_ring_width" = 0;
          "layout.css.prefers-color-scheme.content-override" = 2;
          "browser.privateWindowSeparation.enabled" = false; # WINDOWS
          # COOKIE BANNER HANDLING
          "cookiebanners.service.mode" = 1;
          "cookiebanners.service.mode.privateBrowsing" = 1;
          "cookiebanners.service.enableGlobalRules" = true;
          # FULLSCREEN NOTICE
          "full-screen-api.transition-duration.enter" = "0 0";
          "full-screen-api.transition-duration.leave" = "0 0";
          "full-screen-api.warning.delay" = -1;
          "full-screen-api.warning.timeout" = 0;
          # URL BAR
          "browser.urlbar.suggest.calculator" = true;
          "browser.urlbar.unitConversion.enabled" = true;
          "browser.urlbar.trending.featureGate" = false;
          # NEW TAB PAGE
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          # POCKET
          "browser.pocket.enabled" = false;
          "extensions.pocket.enabled" = false;
          # DOWNLOADS
          "browser.download.panel.shown" = true;
          "browser.download.useDownloadDir" = false;
          "browser.download.always_ask_before_handling_new_types" = true;
          "browser.download.manager.addToRecentDocs" = false;
          # PDF
          "browser.download.open_pdf_attachments_inline" = true;
          # TAB BEHAVIOR
          "browser.bookmarks.openInTabClosesMenu" = false;
          "browser.menu.showViewImageInfo" = true;
          "findbar.highlightAll" = true;
          "layout.word_select.eat_space_to_next_word" = false;
          # LANGUAGE
          "intl.accept_languages" = "en-US, en";
        };
      };
    };

    xdg.mimeApps.defaultApplications = {
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "text/xml" = ["firefox.desktop"];
      "x-scheme-handler/chrome" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
  };
}
