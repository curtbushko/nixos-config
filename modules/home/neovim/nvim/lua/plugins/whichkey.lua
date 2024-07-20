return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = {
        spelling = true,
        presets = {
          operators = true,
        },
      },
      icons = {
        breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
        separator = "   ", -- symbol used between a key and it's label
        group = "+ ", -- symbol prepended to a group
      },
    },
    keys = {
        { "<leader>D", group = "Devdocs", icon = { icon = " ", color = "cyan" } },
    },
    -- config = function(_, opts)
      -- local wk = require("which-key")
  --    wk.setup(opts)
   --   wk.register({
    --    mode = { "n", "v" },
     --   -- Code menus
        --{ "<leader>d", group = "Debug", icon = { icon = " ", color = "red" } },
        --["<leader>c"] = { name = "󱙺 Code" },
        -- Git menus
      --  { "<leader>O", group = "obsidian", icon = { icon = " ", color = "purple" } },
   --     { "<leader>t", group = "terminal", icon = { icon = " ", color = "cyan" } },
  --    })
 --   end,
  },
}
