{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
  colors = lib.importJSON ../styles/${config.curtbushko.theme.name}.json;
in
{
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.zed-editor
    ];

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

        # Disable edit predictions status bar button
        features = {
          edit_prediction_provider = "none";
        };

        # Hide collaboration panel button from status bar
        collaboration_panel = {
          button = false;
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
              background = colors.bg;
              border = colors.bg_dark;
              "border.variant" = colors.bg_float;
              "border.focused" = colors.blue;
              "border.selected" = colors.blue;
              "border.transparent" = colors.bg;
              "border.disabled" = colors.dark3;
              elevated_surface.background = colors.bg_dark;
              surface.background = colors.bg;
              "element.background" = colors.bg_dark;
              "element.hover" = colors.bg_highlight;
              "element.active" = colors.bg_visual;
              "element.selected" = colors.bg_visual;
              "element.disabled" = colors.dark3;
              "drop_target.background" = colors.bg_highlight;
              ghost_element.background = "transparent";
              "ghost_element.hover" = colors.bg_highlight;
              "ghost_element.active" = colors.bg_visual;
              "ghost_element.selected" = colors.bg_visual;
              "ghost_element.disabled" = colors.dark3;
              "text" = colors.fg;
              "text.muted" = colors.comment;
              "text.placeholder" = colors.dark5;
              "text.disabled" = colors.dark5;
              "text.accent" = colors.blue;
              "icon" = colors.fg;
              "icon.muted" = colors.comment;
              "icon.disabled" = colors.dark5;
              "icon.placeholder" = colors.dark5;
              "icon.accent" = colors.blue;
              "status_bar.background" = colors.bg_dark;
              "title_bar.background" = colors.bg_dark;
              "title_bar.inactive_background" = colors.bg;
              "toolbar.background" = colors.bg;
              "tab_bar.background" = colors.bg_dark;
              "tab.inactive_background" = colors.bg_dark;
              "tab.active_background" = colors.bg;
              "search.match_background" = colors.bg_search;
              # Panel background same as editor for unified look
              "panel.background" = colors.bg;
              "panel.focused_border" = colors.blue;
              pane.focused_border = colors.blue;
              "scrollbar.thumb.background" = colors.dark3;
              "scrollbar.thumb.hover_background" = colors.dark5;
              "scrollbar.thumb.border" = colors.dark3;
              "scrollbar.track.background" = colors.bg;
              "scrollbar.track.border" = colors.bg;
              "editor.foreground" = colors.fg;
              "editor.background" = colors.bg;
              "editor.gutter.background" = colors.bg;
              "editor.subheader.background" = colors.bg_dark;
              "editor.active_line.background" = colors.bg_highlight;
              "editor.highlighted_line.background" = colors.bg_visual;
              "editor.line_number" = colors.dark5;
              "editor.active_line_number" = colors.fg;
              "editor.invisible" = colors.dark3;
              "editor.wrap_guide" = colors.dark3;
              "editor.active_wrap_guide" = colors.dark5;
              "editor.document_highlight.read_background" = colors.bg_visual;
              "editor.document_highlight.write_background" = colors.bg_visual;
              "terminal.background" = colors.bg;
              "terminal.foreground" = colors.fg;
              "terminal.bright_foreground" = colors.fg_dark;
              "terminal.dim_foreground" = colors.comment;
              "terminal.ansi.black" = colors.black;
              "terminal.ansi.bright_black" = colors.dark5;
              "terminal.ansi.red" = colors.red;
              "terminal.ansi.bright_red" = colors.red1;
              "terminal.ansi.green" = colors.green;
              "terminal.ansi.bright_green" = colors.green1;
              "terminal.ansi.yellow" = colors.yellow;
              "terminal.ansi.bright_yellow" = colors.warning;
              "terminal.ansi.blue" = colors.blue;
              "terminal.ansi.bright_blue" = colors.blue1;
              "terminal.ansi.magenta" = colors.magenta;
              "terminal.ansi.bright_magenta" = colors.magenta2;
              "terminal.ansi.cyan" = colors.cyan;
              "terminal.ansi.bright_cyan" = colors.teal;
              "terminal.ansi.white" = colors.fg;
              "terminal.ansi.bright_white" = colors.fg_dark;
              link_text.underline = colors.blue;
              conflict = colors.orange;
              "conflict.background" = colors.bg;
              "conflict.border" = colors.orange;
              created = colors.green;
              "created.background" = colors.bg;
              "created.border" = colors.green;
              deleted = colors.red;
              "deleted.background" = colors.bg;
              "deleted.border" = colors.red;
              error = colors.red;
              "error.background" = colors.bg;
              "error.border" = colors.red;
              hidden = colors.dark5;
              "hidden.background" = colors.bg;
              "hidden.border" = colors.dark3;
              hint = colors.orange;
              "hint.background" = colors.bg;
              "hint.border" = colors.orange;
              ignored = colors.dark5;
              "ignored.background" = colors.bg;
              "ignored.border" = colors.dark3;
              info = colors.blue;
              "info.background" = colors.bg;
              "info.border" = colors.blue;
              modified = colors.yellow;
              "modified.background" = colors.bg;
              "modified.border" = colors.yellow;
              predictive = colors.comment;
              "predictive.background" = colors.bg;
              "predictive.border" = colors.comment;
              renamed = colors.cyan;
              "renamed.background" = colors.bg;
              "renamed.border" = colors.cyan;
              success = colors.green;
              "success.background" = colors.bg;
              "success.border" = colors.green;
              unreachable = colors.dark5;
              "unreachable.background" = colors.bg;
              "unreachable.border" = colors.dark3;
              warning = colors.yellow;
              "warning.background" = colors.bg;
              "warning.border" = colors.yellow;
              players = [
                {
                  cursor = colors.blue;
                  background = colors.blue;
                  selection = colors.bg_visual;
                }
                {
                  cursor = colors.green;
                  background = colors.green;
                  selection = colors.bg_visual;
                }
                {
                  cursor = colors.magenta;
                  background = colors.magenta;
                  selection = colors.bg_visual;
                }
                {
                  cursor = colors.orange;
                  background = colors.orange;
                  selection = colors.bg_visual;
                }
                {
                  cursor = colors.cyan;
                  background = colors.cyan;
                  selection = colors.bg_visual;
                }
                {
                  cursor = colors.yellow;
                  background = colors.yellow;
                  selection = colors.bg_visual;
                }
                {
                  cursor = colors.red;
                  background = colors.red;
                  selection = colors.bg_visual;
                }
                {
                  cursor = colors.purple;
                  background = colors.purple;
                  selection = colors.bg_visual;
                }
              ];
              syntax = {
                attribute = {
                  color = colors.cyan;
                };
                boolean = {
                  color = colors.orange;
                };
                comment = {
                  color = colors.comment;
                  font_style = "italic";
                };
                "comment.doc" = {
                  color = colors.comment;
                  font_style = "italic";
                };
                constant = {
                  color = colors.orange;
                };
                constructor = {
                  color = colors.yellow;
                };
                embedded = {
                  color = colors.fg;
                };
                emphasis = {
                  color = colors.red;
                  font_style = "italic";
                };
                "emphasis.strong" = {
                  color = colors.red;
                  font_weight = 700;
                };
                enum = {
                  color = colors.yellow;
                };
                function = {
                  color = colors.green;
                };
                "function.builtin" = {
                  color = colors.green;
                };
                "function.definition" = {
                  color = colors.green;
                };
                "function.method" = {
                  color = colors.green;
                };
                "function.special.definition" = {
                  color = colors.yellow;
                };
                hint = {
                  color = colors.comment;
                  font_weight = 700;
                };
                keyword = {
                  color = colors.red;
                };
                label = {
                  color = colors.cyan;
                };
                link_text = {
                  color = colors.cyan;
                };
                link_uri = {
                  color = colors.blue;
                };
                number = {
                  color = colors.purple;
                };
                operator = {
                  color = colors.orange;
                };
                predictive = {
                  color = colors.comment;
                  font_style = "italic";
                };
                preproc = {
                  color = colors.cyan;
                };
                primary = {
                  color = colors.fg;
                };
                property = {
                  color = colors.blue;
                };
                punctuation = {
                  color = colors.fg;
                };
                "punctuation.bracket" = {
                  color = colors.fg;
                };
                "punctuation.delimiter" = {
                  color = colors.fg;
                };
                "punctuation.list_marker" = {
                  color = colors.orange;
                };
                "punctuation.special" = {
                  color = colors.cyan;
                };
                string = {
                  color = colors.green;
                };
                "string.escape" = {
                  color = colors.orange;
                };
                "string.regex" = {
                  color = colors.orange;
                };
                "string.special" = {
                  color = colors.orange;
                };
                "string.special.symbol" = {
                  color = colors.cyan;
                };
                tag = {
                  color = colors.red;
                };
                "text.literal" = {
                  color = colors.green;
                };
                title = {
                  color = colors.yellow;
                  font_weight = 700;
                };
                type = {
                  color = colors.yellow;
                };
                "type.builtin" = {
                  color = colors.yellow;
                };
                variable = {
                  color = colors.fg;
                };
                "variable.special" = {
                  color = colors.orange;
                };
                variant = {
                  color = colors.cyan;
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
