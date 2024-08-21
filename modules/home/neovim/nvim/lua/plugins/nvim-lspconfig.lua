return {
  {
    "neovim/nvim-lspconfig",
    name = "lspconfig",
    ft = { "nix" },
    opts = {},
    config = function(_, opts)
      local lspconfig = require("lspconfig")
      lspconfig.nil_ls.setup(opts)
    end,
  },
  {
    "neovim/nvim-lspconfig",
    name = "lspconfig.nixd",
    ft = { "nix" },
    opts = {},
    config = function(_, opts)
      require("lspconfig").nixd.setup(opts)
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    name = "lspconfig",
    ft = { "zig" },
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.zls.setup({
        root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
        settings = {
          zls = {
            enable_inlay_hints = true,
            enable_snippets = true,
            warn_style = true,
          },
        },
      })
    end,
  },
}
