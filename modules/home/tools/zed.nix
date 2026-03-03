{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
  isLinux = pkgs.stdenv.isLinux;

  # Read colors from flair's style.json in ~/.config/flair/
  # Note: Requires --impure flag for nix build/home-manager switch
  flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

  # Default fallback colors if flair style.json doesn't exist (gruvbox-material)
  defaultColors = {
    "surface-bg" = "#1d2021";
    "surface-bg-overlay" = "#282828";
    "surface-bg-popup" = "#3c3836";
    "surface-bg-highlight" = "#3c3836";
    "surface-bg-selection" = "#504945";
    "surface-bg-search" = "#504945";
    "text-primary" = "#d4be98";
    "text-secondary" = "#ddc7a1";
    "syntax-comment" = "#928374";
    "syntax-constant" = "#e78a4e";
    "syntax-constructor" = "#d8a657";
    "syntax-function" = "#7daea3";
    "syntax-keyword" = "#ea6962";
    "syntax-number" = "#d3869b";
    "syntax-operator" = "#d4be98";
    "syntax-property" = "#7daea3";
    "syntax-string" = "#a9b665";
    "syntax-escape" = "#e78a4e";
    "syntax-regexp" = "#e78a4e";
    "syntax-tag" = "#ea6962";
    "syntax-type" = "#d8a657";
    "syntax-variable" = "#d4be98";
    "syntax-parameter" = "#d3869b";
    "terminal-black" = "#1d2021";
    "terminal-brblack" = "#928374";
    "terminal-red" = "#ea6962";
    "terminal-brred" = "#ea6962";
    "terminal-green" = "#a9b665";
    "terminal-brgreen" = "#a9b665";
    "terminal-yellow" = "#d8a657";
    "terminal-bryellow" = "#d8a657";
    "terminal-blue" = "#7daea3";
    "terminal-brblue" = "#7daea3";
    "terminal-magenta" = "#d3869b";
    "terminal-brmagenta" = "#d3869b";
    "terminal-cyan" = "#89b482";
    "terminal-brcyan" = "#89b482";
    "terminal-white" = "#d4be98";
    "terminal-brwhite" = "#d4be98";
    "markup-link" = "#7daea3";
    "markup-heading" = "#d8a657";
    "markup-list-bullet" = "#ea6962";
    "git-added" = "#a9b665";
    "git-deleted" = "#ea6962";
    "base00" = "#1d2021";
    "base02" = "#3c3836";
    "base03" = "#504945";
    "base09" = "#e78a4e";
    "base0E" = "#d3869b";
  };

  colors = if builtins.pathExists flairStylePath
           then builtins.fromJSON (builtins.readFile flairStylePath)
           else defaultColors;
in
{
  config = mkIf cfg.enable {
    home.packages = lib.optionals isLinux [
      pkgs.zed-editor
    ];

    xdg.desktopEntries = lib.optionalAttrs isLinux {
      zed = {
        name = "Zed";
        comment = "A high-performance, multiplayer code editor";
        exec = "zed %F";
        icon = "zed";
        terminal = false;
        type = "Application";
        categories = ["Development" "TextEditor" "Utility"];
        mimeType = ["text/plain" "inode/directory"];
      };
    };

    # Zed settings matching neovim configuration
    xdg.configFile."zed/settings.json" = {
      text = builtins.toJSON {
        # Theme - using stylix colors
        theme = "Stylix Dark";

        # Font settings
        buffer_font_family = "FiraCode Nerd Font";
        buffer_font_size = 12;
        buffer_font_features = {
          liga = true;
          calt = true;
        };
        ui_font_family = "FiraCode Nerd Font";
        ui_font_size = 14;

        # Vim mode - matching neovim experience
        vim_mode = true;
        vim = {
          use_system_clipboard = "always";
          use_multiline_find = true;
          use_smartcase_find = true;
        };

        # Editor settings matching neovim options
        tab_size = 2;
        hard_tabs = false; # Use spaces
        show_whitespaces = "selection";
        preferred_line_length = 120;
        soft_wrap = "preferred_line_length";
        scroll_beyond_last_line = "off";
        vertical_scroll_margin = 8;
        relative_line_numbers = false;
        cursor_blink = true;
        show_wrap_guides = true;
        wrap_guides = [ 120 ];

        # UI settings
        scrollbar = {
          show = "auto";
        };
        gutter = {
          line_numbers = true;
          code_actions = true;
          folds = true;
        };
        indent_guides = {
          enabled = true;
          line_width = 1;
          coloring = "fixed";
        };
        inlay_hints = {
          enabled = true;
          show_type_hints = true;
          show_parameter_hints = true;
        };

        # File settings
        remove_trailing_whitespace_on_save = true;
        ensure_final_newline_on_save = true;
        format_on_save = "on";
        autosave = {
          after_delay = {
            milliseconds = 1000;
          };
        };

        # Project panel (like neotree)
        project_panel = {
          dock = "left";
          default_width = 240;
          file_icons = true;
          folder_icons = true;
          git_status = true;
          indent_size = 20;
          auto_reveal_entries = true;
          auto_fold_dirs = true;
        };

        # Terminal settings
        terminal = {
          shell = {
            program = "zsh";
          };
          font_family = "FiraCode Nerd Font";
          font_size = 13;
          line_height = {
            custom = 1.245;
          };
          copy_on_select = true;
        };

        # Git integration
        git = {
          inline_blame = {
            enabled = true;
          };
          git_gutter = "tracked_files";
        };

        # Title bar
        title_bar = {
          show_sign_in = false;
        };

        # Disable edit predictions
        edit_predictions = {
          provider = "none";
          disabled_globs = [
            "**/.env*"
            "**/*.pem"
            "**/*.key"
            "**/*.cert"
            "**/*.crt"
            "**/.dev.vars"
            "**/secrets.yml"
          ];
        };

        # Hide collaboration panel button from status bar
        collaboration_panel = {
          button = false;
        };

        # Agent - only allow Claude Code external agent
        agent = {
          default_model = {
            provider = "claude_code";
            model = "claude_code";
          };
          always_allow_tool_actions = false;
        };

        # Disable all built-in language model providers
        language_models = {
          anthropic = {
            available_models = [];
          };
          openai = {
            available_models = [];
          };
          google = {
            available_models = [];
          };
          copilot_chat = {
            available_models = [];
          };
          ollama = {
            available_models = [];
          };
        };

        # Telemetry
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        # Which-key popup for keybinding hints (Zed Preview 0.219+)
        which_key = {
          enabled = true;
          delay = 500;
        };

        # LSP settings
        lsp = {
          rust-analyzer = {
            initialization_options = {
              checkOnSave = true;
            };
          };
        };

        # Tab bar
        tab_bar = {
          show = true;
          show_nav_history_buttons = false;
        };
        tabs = {
          close_position = "right";
          file_icons = true;
          git_status = true;
        };

        # Minimap disabled (cleaner look)
        minimap = {
          show = "never";
        };

        # Centered layout
        centered_layout = {
          left_padding = 0.15;
          right_padding = 0.15;
        };
      };
    };

    # Zed keymap matching neovim bindings with which-key style menus
    # Menu groups:
    #   <space>b = +buffer
    #   <space>c = +code/lsp
    #   <space>d = +debug
    #   <space>f = +find/file
    #   <space>g = +git
    #   <space>h = +help
    #   <space>m = +marks
    #   <space>n = +notes
    #   <space>o = +open
    #   <space>p = +project
    #   <space>q = +quit
    #   <space>s = +search
    #   <space>t = +terminal/toggle
    #   <space>u = +ui
    #   <space>w = +window
    #   <space>x = +diagnostics
    xdg.configFile."zed/keymap.json" = {
      text = builtins.toJSON [
        # Disable default space action so which-key can intercept it
        {
          context = "VimControl && !menu";
          bindings = {
            "space" = null;
          };
        }

        # Editor context - matching neovim mappings with which-key groups
        {
          context = "Editor && vim_mode == normal && !AssistantPanel";
          bindings = {
            # ============================================
            # Direct leader mappings (no submenu)
            # ============================================
            # Buffer navigation (Tab/Shift-Tab for next/prev buffer)
            "tab" = "pane::ActivateNextItem";
            "shift-tab" = "pane::ActivatePrevItem";

            # Scroll navigation (leader j/k for page down/up)
            "space j" = "editor::MovePageDown";
            "space k" = "editor::MovePageUp";

            # Quick access shortcuts
            "space space" = "file_finder::Toggle"; # Find files
            "space ," = "tab_switcher::Toggle"; # Switch buffer
            "space ." = "file_finder::Toggle"; # Browse files
            "space :" = "command_palette::Toggle"; # Command history
            "space ;" = "command_palette::Toggle"; # Commands
            "space /" = "editor::ToggleComments"; # Comment toggle
            "space `" = "terminal_panel::Toggle"; # Switch to terminal
            "space a" = [
              "agent::NewExternalAgentThread"
              { agent = "claude_code"; }
            ]; # Claude Code
            "space e" = "workspace::ToggleLeftDock"; # Explorer

            # ============================================
            # +buffer (space b)
            # ============================================
            "space b b" = "tab_switcher::Toggle"; # Browse buffers
            "space b c" = "pane::CloseActiveItem"; # Close buffer
            "space b C" = "pane::CloseAllItems"; # Close all buffers
            "space b d" = "pane::CloseActiveItem"; # Delete buffer
            "space b D" = "pane::CloseAllItems"; # Delete all buffers
            "space b f" = "editor::Format"; # Format buffer
            "space b n" = "pane::ActivateNextItem"; # Next buffer
            "space b o" = "pane::CloseOtherItems"; # Close other buffers
            "space b p" = "pane::ActivatePrevItem"; # Previous buffer
            "space b s" = "workspace::Save"; # Save buffer
            "space b S" = "workspace::SaveAll"; # Save all buffers
            "space b w" = "workspace::Save"; # Write buffer
            "space b y" = "editor::Copy"; # Yank buffer (copy all)
            "space b 1" = [
              "pane::ActivateItem"
              0
            ]; # Buffer 1
            "space b 2" = [
              "pane::ActivateItem"
              1
            ]; # Buffer 2
            "space b 3" = [
              "pane::ActivateItem"
              2
            ]; # Buffer 3
            "space b 4" = [
              "pane::ActivateItem"
              3
            ]; # Buffer 4
            "space b 5" = [
              "pane::ActivateItem"
              4
            ]; # Buffer 5
            "space b 6" = [
              "pane::ActivateItem"
              5
            ]; # Buffer 6
            "space b 7" = [
              "pane::ActivateItem"
              6
            ]; # Buffer 7
            "space b 8" = [
              "pane::ActivateItem"
              7
            ]; # Buffer 8
            "space b 9" = [
              "pane::ActivateItem"
              8
            ]; # Buffer 9

            # ============================================
            # +code/lsp (space c)
            # ============================================
            "space c a" = "editor::ToggleCodeActions"; # Code action
            "space c d" = "editor::GoToDefinition"; # Go to definition
            "space c D" = "editor::GoToDeclaration"; # Go to declaration
            "space c f" = "editor::Format"; # Format buffer
            "space c h" = "editor::Hover"; # Hover documentation
            "space c i" = "editor::GoToImplementation"; # Go to implementation
            "space c I" = "editor::ToggleInlayHints"; # Toggle inlay hints
            "space c j" = "editor::GoToDiagnostic"; # Next diagnostic
            "space c k" = "editor::GoToPreviousDiagnostic"; # Prev diagnostic
            "space c l" = "diagnostics::Deploy"; # Line diagnostics
            "space c o" = "outline::Toggle"; # Outline/symbols
            "space c r" = "editor::Rename"; # Rename symbol
            "space c R" = "editor::FindAllReferences"; # Find references
            "space c s" = "outline::Toggle"; # Document symbols
            "space c S" = "project_symbols::Toggle"; # Workspace symbols
            "space c t" = "editor::GoToTypeDefinition"; # Go to type definition
            "space c w" = "project_symbols::Toggle"; # Workspace symbols

            # ============================================
            # +debug (space d) - Limited support, Zed debugger is experimental
            # ============================================
            # Most debugger actions not yet available in stable Zed

            # ============================================
            # +find/file (space f)
            # ============================================
            "space f b" = "tab_switcher::Toggle"; # Find buffer
            "space f c" = "zed::OpenSettings"; # Find config
            "space f e" = "workspace::ToggleLeftDock"; # File explorer
            "space f f" = "file_finder::Toggle"; # Find file
            "space f F" = "file_finder::Toggle"; # Find file (hidden)
            "space f g" = "search::SelectNextMatch"; # Grep/search
            "space f G" = "search::SelectNextMatch"; # Grep (hidden)
            "space f h" = "file_finder::Toggle"; # File history
            "space f n" = "workspace::NewFile"; # New file
            "space f p" = "projects::OpenRecent"; # Recent projects
            "space f r" = "file_finder::Toggle"; # Recent files
            "space f s" = "outline::Toggle"; # File symbols
            "space f S" = "workspace::Save"; # Save file
            "space f t" = "workspace::ToggleLeftDock"; # File tree
            "space f w" = "workspace::Save"; # Write/save file
            "space f y" = "editor::CopyPath"; # Yank file path

            # ============================================
            # +git (space g)
            # ============================================
            "space g B" = "editor::BlameHover"; # Git blame hover
            "space g d" = "editor::ToggleSelectedDiffHunks"; # Diff hunk
            "space g h" = "editor::ToggleSelectedDiffHunks"; # Hunk diff
            "space g n" = "editor::GoToHunk"; # Next hunk
            "space g p" = "editor::GoToPreviousHunk"; # Previous hunk
            "space g r" = "git_panel::ToggleFocus"; # Git panel

            # ============================================
            # +help (space h)
            # ============================================
            "space h c" = "zed::OpenSettings"; # Help config
            "space h k" = "zed::OpenKeymap"; # Keymaps
            "space h m" = "command_palette::Toggle"; # Commands/menu
            "space h t" = "theme_selector::Toggle"; # Themes

            # ============================================
            # +marks (space m) - NOTE: Zed doesn't have bookmark actions yet
            # These bindings are reserved for when bookmarks are added
            # ============================================

            # ============================================
            # +notes (space n)
            # ============================================
            "space n n" = "workspace::NewFile"; # New note
            "space n f" = "file_finder::Toggle"; # Find note
            "space n s" = "workspace::Save"; # Save note

            # ============================================
            # +open (space o)
            # ============================================
            "space o b" = "workspace::ToggleBottomDock"; # Open bottom panel
            "space o d" = "diagnostics::Deploy"; # Open diagnostics
            "space o e" = "workspace::ToggleLeftDock"; # Open explorer
            "space o f" = "workspace::ToggleLeftDock"; # Open file tree
            "space o g" = "git_panel::ToggleFocus"; # Open git panel
            "space o o" = "outline_panel::ToggleFocus"; # Open outline
            "space o p" = "project_panel::ToggleFocus"; # Open project panel
            "space o r" = "workspace::ToggleRightDock"; # Open right panel
            "space o s" = "outline::Toggle"; # Open symbols
            "space o t" = "terminal_panel::Toggle"; # Open terminal

            # ============================================
            # +project (space p)
            # ============================================
            "space p a" = "projects::OpenRecent"; # Add project
            "space p f" = "file_finder::Toggle"; # Project files
            "space p p" = "projects::OpenRecent"; # Switch project
            "space p r" = "projects::OpenRecent"; # Recent projects
            "space p s" = "project_symbols::Toggle"; # Project symbols
            "space p t" = "project_panel::ToggleFocus"; # Project tree

            # ============================================
            # +quit (space q)
            # ============================================
            "space q q" = "zed::Quit"; # Quit
            "space q Q" = "zed::Quit"; # Quit without saving
            "space q w" = "workspace::CloseWindow"; # Close window
            "space q a" = "zed::Quit"; # Quit all

            # ============================================
            # +search (space s)
            # ============================================
            "space s b" = "buffer_search::Deploy"; # Search buffer
            "space s B" = "buffer_search::Deploy"; # Search all buffers
            "space s c" = "command_palette::Toggle"; # Search commands
            "space s d" = "diagnostics::Deploy"; # Search diagnostics
            "space s f" = "file_finder::Toggle"; # Search files
            "space s g" = "search::SelectNextMatch"; # Search/grep project
            "space s h" = "command_palette::Toggle"; # Search help
            "space s j" = "outline::Toggle"; # Jump to symbol
            "space s k" = "zed::OpenKeymap"; # Search keymaps
            "space s n" = "search::SelectNextMatch"; # Next search result
            "space s N" = "search::SelectPrevMatch"; # Prev search result
            "space s p" = "search::SelectNextMatch"; # Search project
            "space s r" = "search::ToggleReplace"; # Search and replace
            "space s s" = "outline::Toggle"; # Search symbols
            "space s S" = "project_symbols::Toggle"; # Search workspace symbols
            "space s t" = "theme_selector::Toggle"; # Search themes
            "space s w" = "editor::SelectAllMatches"; # Search word under cursor

            # ============================================
            # +terminal/toggle (space t)
            # ============================================
            "space t b" = "workspace::ToggleBottomDock"; # Toggle bottom dock
            "space t d" = "diagnostics::Deploy"; # Toggle diagnostics
            "space t e" = "workspace::ToggleLeftDock"; # Toggle explorer
            "space t f" = "editor::ToggleFold"; # Toggle fold
            "space t F" = "editor::UnfoldRecursive"; # Unfold recursive
            "space t g" = "git_panel::ToggleFocus"; # Toggle git panel
            "space t h" = "editor::ToggleInlayHints"; # Toggle inlay hints
            "space t i" = "editor::ToggleInlayHints"; # Toggle inlay hints
            "space t l" = "editor::ToggleLineNumbers"; # Toggle line numbers
            "space t n" = "editor::ToggleLineNumbers"; # Toggle line numbers
            "space t o" = "outline_panel::ToggleFocus"; # Toggle outline
            "space t r" = "workspace::ToggleRightDock"; # Toggle right dock
            "space t s" = "editor::Rewrap"; # Rewrap text
            "space t t" = "terminal_panel::Toggle"; # Toggle terminal
            "space t w" = "editor::Rewrap"; # Rewrap text
            "space t z" = "workspace::ToggleZoom"; # Toggle zoom

            # ============================================
            # +ui (space u)
            # ============================================
            "space u b" = "editor::BlameHover"; # Git blame hover
            "space u c" = "theme_selector::Toggle"; # Change colorscheme
            "space u d" = "diagnostics::Deploy"; # Toggle diagnostics panel
            "space u f" = "zed::ToggleFullScreen"; # Toggle fullscreen
            "space u g" = "editor::BlameHover"; # Git blame hover
            "space u h" = "editor::ToggleInlayHints"; # Toggle hints
            "space u l" = "editor::ToggleLineNumbers"; # Toggle line numbers
            "space u n" = "editor::ToggleLineNumbers"; # Toggle line numbers
            "space u t" = "theme_selector::Toggle"; # Theme selector
            "space u z" = "workspace::ToggleZoom"; # Toggle zoom/zen

            # ============================================
            # +window (space w)
            # ============================================
            "space w c" = "pane::CloseActiveItem"; # Close window/pane
            "space w d" = "pane::CloseActiveItem"; # Delete window
            "space w h" = "workspace::ActivatePaneLeft"; # Window left
            "space w H" = "workspace::SwapPaneLeft"; # Move window left
            "space w j" = "workspace::ActivatePaneDown"; # Window down
            "space w J" = "workspace::SwapPaneDown"; # Move window down
            "space w k" = "workspace::ActivatePaneUp"; # Window up
            "space w K" = "workspace::SwapPaneUp"; # Move window up
            "space w l" = "workspace::ActivatePaneRight"; # Window right
            "space w L" = "workspace::SwapPaneRight"; # Move window right
            "space w m" = "workspace::ToggleZoom"; # Maximize window
            "space w n" = "workspace::NewWindow"; # New window
            "space w o" = "pane::CloseOtherItems"; # Close other windows
            "space w q" = "pane::CloseActiveItem"; # Quit window
            "space w s" = "pane::SplitDown"; # Split horizontal
            "space w t" = "pane::TogglePinTab"; # Toggle pin tab
            "space w v" = "pane::SplitRight"; # Split vertical
            "space w w" = "workspace::ActivatePaneRight"; # Next window
            "space w W" = "workspace::ActivatePaneLeft"; # Prev window
            "space w x" = "pane::CloseActiveItem"; # Close window
            "space w z" = "workspace::ToggleZoom"; # Zoom window
            "space w =" = "workspace::ToggleZoom"; # Balance windows
            "space w -" = "pane::SplitDown"; # Split below
            "space w |" = "pane::SplitRight"; # Split right

            # ============================================
            # +diagnostics (space x)
            # ============================================
            "space x d" = "diagnostics::Deploy"; # Document diagnostics
            "space x l" = "editor::GoToDiagnostic"; # Diagnostics list
            "space x n" = "editor::GoToDiagnostic"; # Next diagnostic
            "space x p" = "editor::GoToPreviousDiagnostic"; # Previous diagnostic
            "space x q" = "diagnostics::Deploy"; # Quickfix list
            "space x w" = "diagnostics::Deploy"; # Workspace diagnostics
            "space x x" = "diagnostics::Deploy"; # Toggle diagnostics

            # ============================================
            # Go to mappings (g prefix)
            # ============================================
            "g d" = "editor::GoToDefinition"; # Go to definition
            "g D" = "editor::GoToDeclaration"; # Go to declaration
            "g f" = "editor::OpenExcerpts"; # Go to file
            "g i" = "editor::GoToImplementation"; # Go to implementation
            "g p" = "editor::GoToDefinitionSplit"; # Peek definition
            "g r" = "editor::FindAllReferences"; # Go to references
            "g s" = "outline::Toggle"; # Go to symbols
            "g t" = "editor::GoToTypeDefinition"; # Go to type definition
            "g b" = "pane::GoBack"; # Go back
            "g n" = "pane::GoForward"; # Go forward
            "g h" = "editor::Hover"; # Hover documentation
            "g c c" = "editor::ToggleComments"; # Comment line
            "g c" = "editor::ToggleComments"; # Comment (operator)

            # Diagnostic navigation
            "] d" = "editor::GoToDiagnostic"; # Next diagnostic
            "[ d" = "editor::GoToPreviousDiagnostic"; # Prev diagnostic
            "] e" = "editor::GoToDiagnostic"; # Next error
            "[ e" = "editor::GoToPreviousDiagnostic"; # Prev error
            "] h" = "editor::GoToHunk"; # Next git hunk
            "[ h" = "editor::GoToPreviousHunk"; # Prev git hunk
            "] b" = "pane::ActivateNextItem"; # Next buffer
            "[ b" = "pane::ActivatePrevItem"; # Prev buffer
            "] q" = "search::SelectNextMatch"; # Next quickfix
            "[ q" = "search::SelectPrevMatch"; # Prev quickfix
            # NOTE: Zed doesn't have bookmark actions yet
            # "] m" and "[ m" reserved for when bookmarks are added

            # Hover
            "shift-k" = "editor::Hover"; # Hover documentation

            # Panel navigation
            "alt-h" = "project_panel::ToggleFocus"; # Move to file browser
            "alt-l" = "assistant::ToggleFocus"; # Move to assistant
          };
        }

        # Insert mode - jj to escape
        {
          context = "Editor && vim_mode == insert";
          bindings = {
            "j j" = "vim::NormalBefore"; # Escape to normal mode
            "j k" = "vim::NormalBefore"; # Escape to normal mode (alt)
          };
        }

        # Visual mode
        {
          context = "Editor && vim_mode == visual";
          bindings = {
            # Maintain selection on indent
            "<" = "editor::Outdent";
            ">" = "editor::Indent";
            # Comment toggle in visual
            "g c" = "editor::ToggleComments";
            "space /" = "editor::ToggleComments";
            # Move lines
            "shift-j" = "editor::MoveLineDown";
            "shift-k" = "editor::MoveLineUp";
          };
        }

        # Terminal panel bindings
        {
          context = "Terminal";
          bindings = {
            "ctrl-`" = "workspace::ToggleBottomDock"; # Toggle terminal
            "ctrl-n" = "workspace::NewTerminal"; # New terminal
            # NOTE: Close/next/prev terminal actions not available in Zed
          };
        }

        # Project panel bindings
        {
          context = "ProjectPanel";
          bindings = {
            "alt-l" = "editor::ToggleFocus"; # Move to editor
            "a" = "project_panel::NewFile"; # Add file
            "A" = "project_panel::NewDirectory"; # Add directory
            "d" = "project_panel::Delete"; # Delete
            "r" = "project_panel::Rename"; # Rename
            "x" = "project_panel::Cut"; # Cut
            "y" = "project_panel::Copy"; # Copy/yank
            "p" = "project_panel::Paste"; # Paste
            "c" = "project_panel::Copy"; # Copy
            "enter" = "project_panel::Open"; # Open
            "o" = "project_panel::Open"; # Open
            "v" = "project_panel::OpenPermanent"; # Open in split
            "s" = "project_panel::OpenPermanent"; # Open split
            "/" = "project_panel::ToggleFocus"; # Search
            "h" = "project_panel::CollapseSelectedEntry"; # Collapse
            "l" = "project_panel::ExpandSelectedEntry"; # Expand
            "j" = "menu::SelectNext"; # Down
            "k" = "menu::SelectPrev"; # Up
            "g g" = "menu::SelectFirst"; # Go to top
            "shift-g" = "menu::SelectLast"; # Go to bottom
            "q" = "workspace::ToggleLeftDock"; # Close panel
            "escape" = "workspace::ToggleLeftDock"; # Close panel
          };
        }

        # Assistant panel bindings
        {
          context = "AssistantPanel";
          bindings = {
            "alt-h" = "editor::ToggleFocus"; # Move to editor
          };
        }

        # Outline panel bindings
        {
          context = "OutlinePanel";
          bindings = {
            "j" = "menu::SelectNext";
            "k" = "menu::SelectPrev";
            "enter" = "outline_panel::Open";
            "o" = "outline_panel::Open";
            "q" = "outline_panel::ToggleFocus";
            "escape" = "outline_panel::ToggleFocus";
            "h" = "outline_panel::CollapseSelectedEntry";
            "l" = "outline_panel::ExpandSelectedEntry";
          };
        }

        # Picker/menu bindings (like telescope)
        {
          context = "Picker";
          bindings = {
            "ctrl-j" = "menu::SelectNext"; # Next item
            "ctrl-k" = "menu::SelectPrev"; # Prev item
            "ctrl-n" = "menu::SelectNext"; # Next item
            "ctrl-p" = "menu::SelectPrev"; # Prev item
            "ctrl-d" = "picker::ConfirmCompletion"; # Confirm
            "ctrl-u" = "picker::ConfirmCompletion"; # Confirm
            "ctrl-c" = "menu::Cancel"; # Cancel
            "escape" = "menu::Cancel"; # Cancel
            "ctrl-v" = "picker::ConfirmCompletion"; # Open in split
            "ctrl-s" = "picker::ConfirmCompletion"; # Open in split
          };
        }

        # Global bindings
        {
          context = "Workspace";
          bindings = {
            # Quick file switching (cmd shortcuts)
            "cmd-p" = "file_finder::Toggle"; # Find files
            "cmd-shift-p" = "command_palette::Toggle"; # Command palette
            "cmd-shift-f" = "search::SelectNextMatch"; # Find in project
            "cmd-b" = "workspace::ToggleLeftDock"; # Toggle sidebar
            "cmd-j" = "workspace::ToggleBottomDock"; # Toggle terminal
            "cmd-\\" = "pane::SplitRight"; # Split right
            "cmd-shift-\\" = "pane::SplitDown"; # Split down
            "cmd-k cmd-t" = "theme_selector::Toggle"; # Theme picker
            "cmd-," = "zed::OpenSettings"; # Open settings
            "cmd-`" = "terminal_panel::Toggle"; # Toggle terminal
            "cmd-;" = [
              "agent::NewExternalAgentThread"
              { agent = "claude_code"; }
            ]; # Claude Code
            "cmd-1" = [
              "pane::ActivateItem"
              0
            ]; # Tab 1
            "cmd-2" = [
              "pane::ActivateItem"
              1
            ]; # Tab 2
            "cmd-3" = [
              "pane::ActivateItem"
              2
            ]; # Tab 3
            "cmd-4" = [
              "pane::ActivateItem"
              3
            ]; # Tab 4
            "cmd-5" = [
              "pane::ActivateItem"
              4
            ]; # Tab 5
            "cmd-6" = [
              "pane::ActivateItem"
              5
            ]; # Tab 6
            "cmd-7" = [
              "pane::ActivateItem"
              6
            ]; # Tab 7
            "cmd-8" = [
              "pane::ActivateItem"
              7
            ]; # Tab 8
            "cmd-9" = [
              "pane::ActivateItem"
              8
            ]; # Tab 9
          };
        }
      ];
    };

    # Custom theme using stylix colors
    xdg.configFile."zed/themes/stylix-theme.json" = {
      text = builtins.toJSON {
        "$schema" = "https://zed.dev/schema/themes/v0.1.0.json";
        name = "Stylix Theme";
        author = "Generated from stylix";
        themes = [
          {
            name = "Stylix Dark";
            appearance = "dark";
            style = {
              background = colors."surface-bg";
              border = colors."surface-bg-overlay";
              "border.variant" = colors."surface-bg-popup";
              "border.focused" = colors."terminal-blue";
              "border.selected" = colors."terminal-blue";
              "border.transparent" = colors."surface-bg";
              "border.disabled" = colors.base02;
              elevated_surface.background = colors."surface-bg-overlay";
              surface.background = colors."surface-bg";
              "element.background" = colors."surface-bg-overlay";
              "element.hover" = colors."surface-bg-highlight";
              "element.active" = colors."surface-bg-selection";
              "element.selected" = colors."surface-bg-selection";
              "element.disabled" = colors.base02;
              "drop_target.background" = colors."surface-bg-highlight";
              ghost_element.background = "transparent";
              "ghost_element.hover" = colors."surface-bg-highlight";
              "ghost_element.active" = colors."surface-bg-selection";
              "ghost_element.selected" = colors."surface-bg-selection";
              "ghost_element.disabled" = colors.base02;
              "text" = colors."text-primary";
              "text.muted" = colors."syntax-comment";
              "text.placeholder" = colors.base03;
              "text.disabled" = colors.base03;
              "text.accent" = colors."terminal-blue";
              "icon" = colors."text-primary";
              "icon.muted" = colors."syntax-comment";
              "icon.disabled" = colors.base03;
              "icon.placeholder" = colors.base03;
              "icon.accent" = colors."terminal-blue";
              "status_bar.background" = colors."surface-bg-overlay";
              "title_bar.background" = colors."surface-bg-overlay";
              "title_bar.inactive_background" = colors."surface-bg";
              "toolbar.background" = colors."surface-bg";
              "tab_bar.background" = colors."surface-bg-overlay";
              "tab.inactive_background" = colors."surface-bg-overlay";
              "tab.active_background" = colors."surface-bg";
              "search.match_background" = colors."surface-bg-search";
              # Panel background same as editor for unified look
              "panel.background" = colors."surface-bg";
              "panel.focused_border" = colors."terminal-blue";
              pane.focused_border = colors."terminal-blue";
              "scrollbar.thumb.background" = colors.base02;
              "scrollbar.thumb.hover_background" = colors.base03;
              "scrollbar.thumb.border" = colors.base02;
              "scrollbar.track.background" = colors."surface-bg";
              "scrollbar.track.border" = colors."surface-bg";
              "editor.foreground" = colors."text-primary";
              "editor.background" = colors."surface-bg";
              "editor.gutter.background" = colors."surface-bg";
              "editor.subheader.background" = colors."surface-bg-overlay";
              "editor.active_line.background" = colors."surface-bg-highlight";
              "editor.highlighted_line.background" = colors."surface-bg-selection";
              "editor.line_number" = colors.base03;
              "editor.active_line_number" = colors."text-primary";
              "editor.invisible" = colors.base02;
              "editor.wrap_guide" = colors.base02;
              "editor.active_wrap_guide" = colors.base03;
              "editor.document_highlight.read_background" = colors."surface-bg-selection";
              "editor.document_highlight.write_background" = colors."surface-bg-selection";
              "terminal.background" = colors."surface-bg";
              "terminal.foreground" = colors."text-primary";
              "terminal.bright_foreground" = colors."text-secondary";
              "terminal.dim_foreground" = colors."syntax-comment";
              "terminal.ansi.black" = colors."terminal-black";
              "terminal.ansi.bright_black" = colors."terminal-brblack";
              "terminal.ansi.red" = colors."terminal-red";
              "terminal.ansi.bright_red" = colors."terminal-brred";
              "terminal.ansi.green" = colors."terminal-green";
              "terminal.ansi.bright_green" = colors."terminal-brgreen";
              "terminal.ansi.yellow" = colors."terminal-yellow";
              "terminal.ansi.bright_yellow" = colors."terminal-bryellow";
              "terminal.ansi.blue" = colors."terminal-blue";
              "terminal.ansi.bright_blue" = colors."terminal-brblue";
              "terminal.ansi.magenta" = colors."terminal-magenta";
              "terminal.ansi.bright_magenta" = colors."terminal-brmagenta";
              "terminal.ansi.cyan" = colors."terminal-cyan";
              "terminal.ansi.bright_cyan" = colors."terminal-brcyan";
              "terminal.ansi.white" = colors."terminal-white";
              "terminal.ansi.bright_white" = colors."terminal-brwhite";
              link_text.underline = colors."terminal-blue";
              conflict = colors.base09;
              "conflict.background" = colors."surface-bg";
              "conflict.border" = colors.base09;
              created = colors."terminal-green";
              "created.background" = colors."surface-bg";
              "created.border" = colors."terminal-green";
              deleted = colors."terminal-red";
              "deleted.background" = colors."surface-bg";
              "deleted.border" = colors."terminal-red";
              error = colors."terminal-red";
              "error.background" = colors."surface-bg";
              "error.border" = colors."terminal-red";
              hidden = colors.base03;
              "hidden.background" = colors."surface-bg";
              "hidden.border" = colors.base02;
              hint = colors.base09;
              "hint.background" = colors."surface-bg";
              "hint.border" = colors.base09;
              ignored = colors.base03;
              "ignored.background" = colors."surface-bg";
              "ignored.border" = colors.base02;
              info = colors."terminal-blue";
              "info.background" = colors."surface-bg";
              "info.border" = colors."terminal-blue";
              modified = colors."terminal-yellow";
              "modified.background" = colors."surface-bg";
              "modified.border" = colors."terminal-yellow";
              predictive = colors."syntax-comment";
              "predictive.background" = colors."surface-bg";
              "predictive.border" = colors."syntax-comment";
              renamed = colors."terminal-cyan";
              "renamed.background" = colors."surface-bg";
              "renamed.border" = colors."terminal-cyan";
              success = colors."terminal-green";
              "success.background" = colors."surface-bg";
              "success.border" = colors."terminal-green";
              unreachable = colors.base03;
              "unreachable.background" = colors."surface-bg";
              "unreachable.border" = colors.base02;
              warning = colors."terminal-yellow";
              "warning.background" = colors."surface-bg";
              "warning.border" = colors."terminal-yellow";
              players = [
                {
                  cursor = colors."terminal-blue";
                  background = colors."terminal-blue";
                  selection = colors."surface-bg-selection";
                }
                {
                  cursor = colors."terminal-green";
                  background = colors."terminal-green";
                  selection = colors."surface-bg-selection";
                }
                {
                  cursor = colors."terminal-magenta";
                  background = colors."terminal-magenta";
                  selection = colors."surface-bg-selection";
                }
                {
                  cursor = colors.base09;
                  background = colors.base09;
                  selection = colors."surface-bg-selection";
                }
                {
                  cursor = colors."terminal-cyan";
                  background = colors."terminal-cyan";
                  selection = colors."surface-bg-selection";
                }
                {
                  cursor = colors."terminal-yellow";
                  background = colors."terminal-yellow";
                  selection = colors."surface-bg-selection";
                }
                {
                  cursor = colors."terminal-red";
                  background = colors."terminal-red";
                  selection = colors."surface-bg-selection";
                }
                {
                  cursor = colors.base0E;
                  background = colors.base0E;
                  selection = colors."surface-bg-selection";
                }
              ];
              syntax = {
                attribute = {
                  color = colors."terminal-cyan";
                };
                boolean = {
                  color = colors.base09;
                };
                comment = {
                  color = colors."syntax-comment";
                  font_style = "italic";
                };
                "comment.doc" = {
                  color = colors."syntax-comment";
                  font_style = "italic";
                };
                constant = {
                  color = colors."syntax-constant";
                };
                constructor = {
                  color = colors."syntax-constructor";
                };
                embedded = {
                  color = colors."text-primary";
                };
                emphasis = {
                  color = colors."terminal-red";
                  font_style = "italic";
                };
                "emphasis.strong" = {
                  color = colors."terminal-red";
                  font_weight = 700;
                };
                enum = {
                  color = colors."syntax-type";
                };
                function = {
                  color = colors."syntax-function";
                };
                "function.builtin" = {
                  color = colors."syntax-function";
                };
                "function.definition" = {
                  color = colors."syntax-function";
                };
                "function.method" = {
                  color = colors."syntax-function";
                };
                "function.special.definition" = {
                  color = colors."syntax-type";
                };
                hint = {
                  color = colors."syntax-comment";
                  font_weight = 700;
                };
                keyword = {
                  color = colors."syntax-keyword";
                };
                label = {
                  color = colors."terminal-cyan";
                };
                link_text = {
                  color = colors."markup-link";
                };
                link_uri = {
                  color = colors."terminal-blue";
                };
                number = {
                  color = colors."syntax-number";
                };
                operator = {
                  color = colors."syntax-operator";
                };
                predictive = {
                  color = colors."syntax-comment";
                  font_style = "italic";
                };
                preproc = {
                  color = colors."terminal-cyan";
                };
                primary = {
                  color = colors."text-primary";
                };
                property = {
                  color = colors."syntax-property";
                };
                punctuation = {
                  color = colors."text-primary";
                };
                "punctuation.bracket" = {
                  color = colors."text-primary";
                };
                "punctuation.delimiter" = {
                  color = colors."text-primary";
                };
                "punctuation.list_marker" = {
                  color = colors."markup-list-bullet";
                };
                "punctuation.special" = {
                  color = colors."terminal-cyan";
                };
                string = {
                  color = colors."syntax-string";
                };
                "string.escape" = {
                  color = colors."syntax-escape";
                };
                "string.regex" = {
                  color = colors."syntax-regexp";
                };
                "string.special" = {
                  color = colors.base09;
                };
                "string.special.symbol" = {
                  color = colors."terminal-cyan";
                };
                tag = {
                  color = colors."syntax-tag";
                };
                "text.literal" = {
                  color = colors."syntax-string";
                };
                title = {
                  color = colors."markup-heading";
                  font_weight = 700;
                };
                type = {
                  color = colors."syntax-type";
                };
                "type.builtin" = {
                  color = colors."syntax-type";
                };
                variable = {
                  color = colors."syntax-variable";
                };
                "variable.special" = {
                  color = colors."syntax-parameter";
                };
                variant = {
                  color = colors."terminal-cyan";
                };
              };
            };
          }
        ];
      };
    };

    # Global snippets (all languages)
    # NOTE: Zed does not support VSCode date variables (CURRENT_YEAR, etc.)
    xdg.configFile."zed/snippets/snippets.json" = {
      text = builtins.toJSON {
        "todo comment" = {
          prefix = "todo";
          body = "// TODO: $1";
          description = "add a todo item";
        };
        "fixme comment" = {
          prefix = "fixme";
          body = "// FIXME: $1";
          description = "add a fixme item";
        };
        "note comment" = {
          prefix = "note";
          body = "// NOTE: $1";
          description = "add a note comment";
        };
        "obsidian note header" = {
          prefix = "obsidian";
          body = "---\nTitle: $1\nDate: $2\n---\n#untagged";
          description = "obsidian note header with manual date entry";
        };
      };
    };

    # Go snippets
    xdg.configFile."zed/snippets/go.json" = {
      text = builtins.toJSON {
        "if err" = {
          prefix = "iferr";
          body = "if err != nil {\n\treturn nil, err\n}";
          description = "if err != nil statement";
        };
        "test got want" = {
          prefix = "testgot";
          body = "if got != want{\n\tt.Errorf(\"got %q, wanted %q\", got, want)\n}";
          description = "simple if got want t.Errorf statement";
        };
        "test want got" = {
          prefix = "testwant";
          body = "if want != got{\n\tt.Errorf(\"wanted %q, got %q\", want, got)\n}";
          description = "simple if want got t.Errorf statement";
        };
        "if got" = {
          prefix = "ifgot";
          body = "if got != want{\n\tt.Errorf(\"got %q, wanted %q\", got, want)\n}";
          description = "simple if got want t.Errorf statement";
        };
        "if want" = {
          prefix = "ifwant";
          body = "if want != got{\n\tt.Errorf(\"wanted %q, got %q\", want, got)\n}";
          description = "simple if want got t.Errorf statement";
        };
        "t.Errorf" = {
          prefix = "terr";
          body = "t.Errorf(\"got %q, wanted %q\", got, want)\n";
          description = "simple t.Errorf got want statement";
        };
        "t.Run" = {
          prefix = "trun";
          body = "t.Run(\"$1\", func(t *testing.T) {\n\t$2\n})";
          description = "embedded test run in a test case";
        };
        "table driven test" = {
          prefix = "tdd";
          body = "func Test$1(t *testing.T) {\n\tcases := []struct {\n\t\tname string\n\t\tactual string\n\t\twant string\n\t}{\n\t\t{\n\t\t\tname: \"\",\n\t\t\tactual: \"\",\n\t\t\twant: \"\",\n\t\t},\n\t}\n\tfor _, c := range cases {\n\t\tt.Run(c.name, func(t *testing.T) {\n\t\t\tgot := $2(c.actual)\n\t\t\tif got != c.want {\n\t\t\t\tt.Errorf(\"got %v, want %v\", got, c.want)\n\t\t\t}\n\t\t})\n\t}\n}";
          description = "snippet for table driven test";
        };
        "func test" = {
          prefix = "functest";
          body = "func Test$1(t *testing.T) {\n\t$0\n}";
          description = "snippet for simple test function";
        };
        "for i loop" = {
          prefix = "fori";
          body = "for i := 0; i < len($1); i++ {\n\t$0\n}\n";
          description = "simple for loop with initializing i";
        };
        "go func" = {
          prefix = "gofunc";
          body = "go func() {\n\t$1\n}()\n";
          description = "simple anonymized go func";
        };
        "make chan" = {
          prefix = "makechan";
          body = "ch := make(chan struct{})\n";
          description = "simple no allocation channel";
        };
        "interface guard" = {
          prefix = "interfaceguard";
          body = "var _ $1 = (*$2)(nil)";
          description = "interface guard to check struct satisfies interface";
        };
        "slice append" = {
          prefix = "sliceappend";
          body = "a = append(a, b...)";
          description = "slice append vector";
        };
        "slice copy" = {
          prefix = "slicecopy";
          body = "b := make([]$1, len(a))\ncopy(b, a)";
          description = "slice copy";
        };
        "slice push" = {
          prefix = "slicepush";
          body = "a = append(a, x)";
          description = "slice push";
        };
        "slice pop" = {
          prefix = "slicepop";
          body = "x, a = a[len(a)-1], a[:len(a)-1]";
          description = "slice pop";
        };
        "linked list" = {
          prefix = "linkedlist";
          body = "type element struct {\n\tname string\n\tnext *element\n}\n\ntype list struct {\n\tname string\n\thead *element\n}";
          description = "single linked list";
        };
        "bfs" = {
          prefix = "bfs";
          body = "type Node struct {\n\tValue    int\n\tChildren []*Node\n}\n\nfunc (n *Node) BreadthFirstSearch(array []int) []int {\n\tqueue := []*Node{n}\n\tfor len(queue) > 0 {\n\t\tcurrent := queue[0]\n\t\tqueue = queue[1:]\n\t\tarray = append(array, current.Value)\n\t\tfor _, child := range current.Children {\n\t\t\tqueue = append(queue, child)\n\t\t}\n\t}\n\treturn array\n}\n";
          description = "breadth-first search";
        };
        "dfs" = {
          prefix = "dfs";
          body = "type Node struct {\n\tValue    int\n\tChildren []*Node\n}\n\nfunc (n *Node) DepthFirstSearch(array []int) []int {\n\tarray = append(array, n.Value)\n\tfor _, child := range n.Children {\n\t\tarray = child.DepthFirstSearch(array)\n\t}\n\treturn array\n}\n";
          description = "depth-first search";
        };
      };
    };

    # Zig snippets
    xdg.configFile."zed/snippets/zig.json" = {
      text = builtins.toJSON {
        "var decl" = {
          prefix = "var";
          body = [ "var \${1:name}: \${2:type} = $0;" ];
          description = "var decl";
        };
        "const decl" = {
          prefix = "const";
          body = [ "const \${1:name}: \${2:type} = $0;" ];
          description = "const decl";
        };
        "fn decl" = {
          prefix = "fn";
          body = [
            "fn \${1:name}(\${2:arguments}) {"
            "    $0"
            "}"
          ];
          description = "fn decl";
        };
        "pub fn decl" = {
          prefix = "pub_fn";
          body = [
            "pub fn \${1:name}(\${2:arguments}) {"
            "    $0"
            "}"
          ];
          description = "pub fn decl";
        };
        "generic fn" = {
          prefix = "fn_gen";
          body = [
            "fn \${1:name}(comptime T: type, $2) type {"
            "    $0"
            "}"
          ];
          description = "generic fn decl";
        };
        "struct decl" = {
          prefix = "stru_decl";
          body = [
            "const \${1:StructName} = struct {"
            "    $0"
            "};"
          ];
          description = "struct decl";
        };
        "enum decl" = {
          prefix = "enum";
          body = [
            "const \${1:EnumName} = enum(\${2:type}) {"
            "    $0"
            "};"
          ];
          description = "enum decl";
        };
        "union decl" = {
          prefix = "union";
          body = [
            "const \${1:UnionName} = union(\${2:enum}) {"
            "    $0"
            "};"
          ];
          description = "tagged union decl";
        };
        "for value" = {
          prefix = "for_v";
          body = [
            "for ($0) |\${1:v}| {"
            "    "
            "}"
          ];
          description = "for value loop";
        };
        "for value index" = {
          prefix = "for_v_i";
          body = [
            "for ($0) |\${1:v}, \${2:i}| {"
            "    "
            "}"
          ];
          description = "for value,index loop";
        };
        "while loop" = {
          prefix = "while";
          body = [
            "while ($0) : () {"
            "    "
            "}"
          ];
          description = "while loop";
        };
        "if expr" = {
          prefix = "if";
          body = [
            "if (\${1:statement}) {"
            "    $0"
            "}"
          ];
          description = "if expr";
        };
        "if else" = {
          prefix = "if_else";
          body = [
            "if (\${1:statement}) {"
            "    $0"
            "} else {"
            "    "
            "}"
          ];
          description = "if else expr";
        };
        "if optional" = {
          prefix = "if?";
          body = [
            "if (\${1:statement}) |v| {"
            "    $0"
            "}"
          ];
          description = "if optional";
        };
        "switch expr" = {
          prefix = "switch";
          body = [
            "switch (\${1:statement}) {"
            "     => ,"
            "    else => ,"
            "};"
          ];
          description = "switch expr";
        };
        "test" = {
          prefix = "test";
          body = [
            "test \"\${1:name}\" {"
            "    $0"
            "}"
          ];
          description = "test";
        };
        "defer block" = {
          prefix = "def";
          body = [
            "defer {"
            "    $0"
            "}"
          ];
          description = "defer block";
        };
        "errdefer block" = {
          prefix = "errd";
          body = [
            "errdefer {"
            "    $0"
            "}"
          ];
          description = "errdefer block";
        };
        "import std" = {
          prefix = "imps";
          body = [ "const std = @import(\"std\");" ];
          description = "import std";
        };
        "main template" = {
          prefix = "main";
          body = [
            "const std = @import(\"std\");"
            ""
            "pub fn main() void {"
            "    const stdout = std.io.getStdOut().writer();"
            "    try stdout.print(\"Hello, {s}!\\n\", .{\"world\"});$0"
            "}"
          ];
          description = "main/hello world";
        };
        "orelse" = {
          prefix = "orelse";
          body = [ "orelse return $0" ];
          description = "orelse expr";
        };
        "catch block" = {
          prefix = "catch";
          body = [
            "catch |$1| {"
            "    $0"
            "};"
          ];
          description = "catch error block";
        };
        "comptime block" = {
          prefix = "comp";
          body = [
            "comptime {"
            "    $0"
            "}"
          ];
          description = "comptime block";
        };
      };
    };
  };
}
