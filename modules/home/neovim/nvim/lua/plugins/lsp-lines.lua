return {
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()

      -- disable virtual_text since it's redundant due to lsp_lines.
      vim.diagnostic.config({ virtual_text = false })
      vim.diagnostic.config({ virtual_lines = { only_current_line = true } })
    end,
  },
}
