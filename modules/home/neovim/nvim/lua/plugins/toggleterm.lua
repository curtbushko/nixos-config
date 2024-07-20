return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      float_opts = {
        border = "curved",
        width = 90,
        height = 30,
      },
    },
    keys = {
      { "<leader>t", "", desc = "+terminal", { icon = "  ", color = "cyan" } },
      {
        "<leader>tf",
        "<CMD>ToggleTerm float_opts.width=20 direction=float<CR>",
        desc = "float",
      },
    },
  },
}
