let
  # Required fields and action IDs from OmniWM 0.7.4's exported defaults.
  # The pinned Home Manager predates programs.omniwm; manage TOML directly.
  defaults = builtins.fromJSON (builtins.readFile ./defaults.json);
  hotkeyIds = builtins.fromJSON (builtins.readFile ./hotkey-ids.json);
in
  defaults
  // {
    general =
      defaults.general
      // {
        defaultLayoutType = "niri";
        hotkeysEnabled = false; # skhd supports aliases and launching applications.
        ipcEnabled = true;
      };
    focus =
      defaults.focus
      // {
        followsMouse = true;
        moveMouseToFocusedWindow = true;
        crossesMonitorAtEdge = true;
        followsWindowToMonitor = true;
      };
    gaps =
      defaults.gaps
      // {
        size = 6;
        fullscreenUsesOuterGaps = true;
        outer = {
          left = 6;
          right = 6;
          top = 6;
          bottom = 6;
        };
      };
    niri =
      defaults.niri
      // {
        visibleContainerCount = 3;
        containerPrimarySpanPresets = [0.33333 0.5 0.66667];
        defaultContainerPrimarySpan = 1.0;
        resizeStepPercent = 10;
        singleWindowFit = "container_primary_span";
      };
    borders =
      defaults.borders
      // {
        enabled = true;
        width = 1;
        color = {
          red = 125.0 / 255;
          green = 174.0 / 255;
          blue = 163.0 / 255;
          alpha = 1.0;
        };
      };
    workspaceBar =
      defaults.workspaceBar
      // {
        enabled = false;
        position = "overlappingMenuBar";
        notchMode = "fillLeftOfNotch";
        reserveLayoutSpace = false;
      };
    clipboard = defaults.clipboard // {historyEnabled = true;};
    quakeTerminal = defaults.quakeTerminal // {enabled = false;};
    hiddenBar = defaults.hiddenBar // {enabled = false;};
    # Required even with native hotkeys disabled; no competing Option defaults.
    hotkeys =
      map (id: {
        inherit id;
        binding = "Unassigned";
      })
      hotkeyIds;
    workspaces =
      builtins.genList (index: {
        id = "00000000-0000-4000-8000-00000000000${toString (index + 1)}";
        name = toString (index + 1);
        layoutType = "niri";
        monitorAssignment.type = "main";
      })
      1;
    appRules = [
      {
        id = "00000000-0000-4000-9000-000000000001";
        bundleId = "md.obsidian";
        initialContainerPrimarySpan = 1.0;
      }
      {
        id = "00000000-0000-4000-9000-000000000002";
        bundleId = ""; # Required by the decoder; empty matches any application.
        titleRegex = "^(Picture-in-Picture|Picture in picture|Discord Popout|floating)$";
        layout = "float";
      }
      {
        id = "00000000-0000-4000-9000-000000000003";
        bundleId = "com.mitchellh.ghostty";
        minWidth = 90;
        minHeight = 48;
      }
    ];
  }
