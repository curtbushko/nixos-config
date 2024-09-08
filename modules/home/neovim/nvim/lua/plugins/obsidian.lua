return {
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
          enable = true, -- set to false to disable all additional syntax features
          update_debounce = 200, -- update delay after a text change (in milliseconds)
          max_file_length = 5000, -- disable UI features for files with more than this many lines
          -- Define how various check-boxes are displayed
          checkboxes = {
            -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
            [" "] = { char = "󰄱 ", hl_group = "ObsidianTodo" },
            ["x"] = { char = " ", hl_group = "ObsidianDone" },
            [">"] = { char = " ", hl_group = "ObsidianRightArrow" },
            ["~"] = { char = "󰰱 ", hl_group = "ObsidianTilde" },
            ["!"] = { char = " ", hl_group = "ObsidianImportant" },
            -- Replace the above with this if you don't have a patched font:
            -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
            -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

            -- You can also add more custom ones...
          },
          -- Use bullet marks for non-checkbox lists.
          bullets = { char = "•", hl_group = "ObsidianBullet" },
          external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
          -- Replace the above with this if you don't have a patched font:
          -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
          reference_text = { hl_group = "ObsidianRefText" },
          highlight_text = { hl_group = "ObsidianHighlightText" },
          tags = { hl_group = "ObsidianTag" },
          block_ids = { hl_group = "ObsidianBlockID" },
          hl_groups = {
            -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
            ObsidianTodo = { bold = true, fg = "#f78c6c" },
            ObsidianDone = { bold = true, fg = "#89ddff" },
            ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
            ObsidianTilde = { bold = true, fg = "#ff5370" },
            ObsidianImportant = { bold = true, fg = "#d73128" },
            ObsidianBullet = { bold = true, fg = "#89ddff" },
            ObsidianRefText = { underline = true, fg = "#c792ea" },
            ObsidianExtLinkIcon = { fg = "#c792ea" },
            ObsidianTag = { italic = true, fg = "#89ddff" },
            ObsidianBlockID = { italic = true, fg = "#89ddff" },
            ObsidianHighlightText = { bg = "#75662e" },
          },
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
