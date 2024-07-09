-- bootstrap lazy.nvim, LazyVim and your plugins
vim.g.lazyvim_json = vim.fn.stdpath("cache") .. "nvim" .. "/lazyvim.json"
require("config.lazy")
