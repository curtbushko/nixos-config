{
 home.sessionVariables.VTE_VERSION = "5803";

  programs.nixvim = {
    enable = true;

    viAlias = true;
    vimalias = true;

    package = pkgs.neovim-unwrapped;

    globals.mapleader = " ";

    options = {
      # mouse support
      mouse = "a";
      mousemoveevent = true;

      # background
      background = "dark";

      # enable filetype indentation
      #filetype plugin indent on

      termguicolors = true;

      # Line Numbers
      number = true;
      relativenumber = true;

      # Spellcheck
      spelllang = "en_us";

      # Use X clipboard
      clipboard = "unnamedplus";

      # Some defaults
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;

      # backupdir = "~/.config/nvim/backup";
      # directory = "~/.config/nvim/swap";
      # undodir = "~/.config/nvim/undo";
      #
    };

    maps = {
      # Disable middle-click paste (triggers when scrolling with trackpoint)
      normalVisualOp."<MiddleMouse>" = "<nop>";
      insert."<MiddleMouse>" = "<nop>";
    };

    plugins.specs = {
      enable = true;
      color = "#ff00ff";
    };

    plugins.notify = {
      enable = true;
      backgroundColour = "#00000000";
    };

    editorconfig.enable = true;
    plugins.trouble.enable = true;

    plugins.lualine = {
      enable = true;
      sections = {
        lualine_c = [
          {
            extraConfig = {
              path = 1;
              newfile_status = true;
            };
          }
        ];
      };
    };

    # plugins.nvim-cmp = {
    #   enable = true;
    # };

    extraPlugins = with pkgs.vimPlugins; [
      # vim-wakatime
    ];
  };
}
