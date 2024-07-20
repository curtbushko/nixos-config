return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
        end,
        desc = "Find Plugin File",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Find buffers",
      },
      {
        "<leader>,",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "Switch Buffer",
      },
      {
        "<leader>fc",
        function()
          require("telescope.builtin").grep_string()
        end,
        desc = "Find text under cursor",
      },
      {
        "<leader>fT",
        ":Telescope file_browser hidden=true<CR>",
        desc = "Telescope Explorer (hidden)",
      },
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({ cwd = ".", hidden = false })
        end,
        desc = "Find files",
      },
      {
        "<leader><space>",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "Find files",
      },

      {
        "<leader>fF",
        function()
          require("telescope.builtin").find_files({ cwd = ".", hidden = true, no_ignore = true })
        end,
        desc = "Find all files",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Help",
      },
      {
        "<leader>fk",
        function()
          require("telescope.builtin").keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>fm",
        function()
          require("telescope.builtin").marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>fn",
        "<CMD>enew<CR>",
        desc = "New File",
      },
      {
        "<leader>fr",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "Recent",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>/",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Grep",
      },

      {
        "<leader>fs",
        function()
          require("telescope.builtin").lsp_document_symbols()
        end,
        desc = " Symbols",
      },
      {
        "<leader>ft",
        ":TodoTelescope<CR>",
        desc = "Todo",
      },
      {
        "<leader>fG",
        function()
          require("telescope.builtin").live_grep({
            additional_args = function(args)
              return vim.list_extend(args, { "--hidden", "--no-ignore" })
            end,
          })
        end,
        desc = "Grep all files (hidden)",
      },
      -- git keymaps
      {
        "<leader>gc",
        ":Telescope git_commits<CR>",
        desc = "Commits",
      },
      {
        "<leader>gb",
        ":Telescope git_branches<CR>",
        desc = "Branches",
      },
      {
        "<leader>gs",
        ":Telescope git_status<CR>",
        desc = "Status",
      },
      {
        "<leader>fR",
        function()
          local cwd = vim.fn.getcwd()
          require("telescope.builtin").oldfiles({ cwd })
        end,
        desc = "Recent (cwd)",
      },
      {
        "<leader>:",
        "<cmd>Telescope command_history<cr>",
        desc = "Command History",
      },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          i = {
            ["<C-n"] = function(...)
              return require("telescope.actions").cycle_history_next(...)
            end,
            ["<C-p>"] = function(...)
              return require("telescope.actions").cycle_history_prev(...)
            end,
            ["<C-j>"] = function(...)
              return require("telescope.actions").preview_scrolling_down(...)
            end,
            ["<C-k>"] = function(...)
              return require("telescope.actions").preview_scrolling_up(...)
            end,
            ["<C-h>"] = function(...)
              return require("telescope.actions").preview_scrolling_left(...)
            end,
            ["<C-l>"] = function(...)
              return require("telescope.actions").preview_scrolling_right(...)
            end,
          },
          n = {
            ["q"] = function(...)
              return require("telescope.actions").close(...)
            end,
            ["<C-j>"] = function(...)
              return require("telescope.actions").preview_scrolling_down(...)
            end,
            ["<C-k>"] = function(...)
              return require("telescope.actions").preview_scrolling_up(...)
            end,
            ["<C-h>"] = function(...)
              return require("telescope.actions").preview_scrolling_left(...)
            end,
            ["<C-l>"] = function(...)
              return require("telescope.actions").preview_scrolling_right(...)
            end,
          },
        },
      },
    },
  },

  -- add telescope-fzf-native
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
        require("telescope").load_extension("harpoon")
        require("telescope").load_extension("yank_history")
        require("telescope").load_extension("todo-comments")
        require("telescope").load_extension("file_browser")
      end,
    },
  },

  {
    "nvim-telescope/telescope-file-browser.nvim",
  },
}
