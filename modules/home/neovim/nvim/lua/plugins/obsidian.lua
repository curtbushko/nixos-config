return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      checkbox = {
        -- Turn on / off checkbox state rendering
        enabled = true,
        -- Determines how icons fill the available space:
        --  inline:  underlying text is concealed resulting in a left aligned icon
        --  overlay: result is left padded with spaces to hide any additional text
        position = "inline",
        unchecked = {
          -- Replaces '[ ]' of 'task_list_marker_unchecked'
          icon = "󰄱 ",
          -- Highlight for the unchecked icon
          highlight = "RenderMarkdownUnchecked",
        },
        checked = {
          -- Replaces '[x]' of 'task_list_marker_checked'
          icon = " ",
          -- Highligh for the checked icon
          highlight = "RenderMarkdownChecked",
        },
        -- Define custom checkbox states, more involved as they are not part of the markdown grammar
        -- As a result this requires neovim >= 0.10.0 since it relies on 'inline' extmarks
        -- Can specify as many additional states as you like following the 'todo' pattern below
        --   The key in this case 'todo' is for healthcheck and to allow users to change its values
        --   'raw':       Matched against the raw text of a 'shortcut_link'
        --   'rendered':  Replaces the 'raw' value when rendering
        --   'highlight': Highlight for the 'rendered' icon
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          todo = { raw = "[>]", rendered = "󱞬 ", highlight = "RenderMarkdownTodo" },
        },
      },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  },

  {
    "epwalsh/obsidian.nvim",
    config = function()
      require("obsidian").setup({
        dir = "~/workspace/github.com/curtbushko/kb",
        id = {},
        daily_notes = {
          folder = "daily",
          date_format = "%Y%m%d",
        },
        disable_frontmatter = true,
        note_id_func = function()
          return tostring(os.date("%Y%m%d-%H%M"))
        end,
        templates = {
          subdir = "templates",
          date_format = "%Y%m%d-%a",
          time_format = "%H:%M",
        },
        preferred_link_style = "markdown",

        ui = {
          enable = false, -- set to false to disable all additional syntax features
        },
      })
    end,
    -- :ObsidianBacklinks for getting a location list of references to the current buffer.
    -- :ObsidianToday to create a new daily note.
    -- :ObsidianYesterday to open (eventually creating) the daily note for the previous working day.
    -- :ObsidianOpen to open a note in the Obsidian app. This command has one optional argument: the ID, path, or alias of the note to open. If not given, the note corresponding to the current buffer is opened.
    -- :ObsidianNew to create a new note. This command has one optional argument: the title of the new note.
    -- :ObsidianSearch to search for notes in your vault using ripgrep with fzf.vim, fzf-lua or telescope.nvim. This command has one optional argument: a search query to start with.
    -- :ObsidianQuickSwitch to quickly switch to another notes in your vault, searching by its name using fzf.vim, fzf-lua or telescope.nvim.
    -- :ObsidianLink to link an in-line visual selection of text to a note. This command has one optional argument: the ID, path, or alias of the note to link to. If not given, the selected text will be used to find the note with a matching ID, path, or alias.
    -- :ObsidianLinkNew to create a new note and link it to an in-line visual selection of text. This command has one optional argument: the title of the new note. If not given, the selected text will be used as the title.
    -- :ObsidianFollowLink to follow a note reference under the cursor.
    --
    keys = {
      { "<leader>Ob", "<CMD>ObsidianBacklinks<CR>", desc = "backlinks" },
      { "<leader>Od", "<CMD>ObsidianToday<CR>", desc = "new daily note" },
      { "<leader>Of", "gf", desc = "follow link" },
      { "<leader>Ol", "<CMD>ObsidianLink<CR>", desc = "link" },
      { "<leader>Om", "<CMD>ObsidianLinkNew<CR>", desc = "new note from link" },
      { "<leader>On", "<CMD>ObsidianNew<CR>", desc = "new note" },
      { "<leader>Oy", "<CMD>ObsidianYesterday<CR>", desc = "yesterdays daily note" },
    },
  },
}
