return {
  {
    "ThePrimeagen/harpoon",
    lazy = true,
    keys = {
      {
        "<leader>ha",
        function()
          require("harpoon.mark").add_file()
        end,
        desc = " Add",
      },
      {
        "<leader>hn",
        function()
          require("harpoon.ui").nav_next()
        end,
        desc = " Next",
      },
      {
        "<leader>hp",
        function()
          require("harpoon.ui").nav_prev()
        end,
        desc = " Previous",
      },
      {
        "<leader>hh",
        function()
          require("harpoon.ui").toggle_quick_menu()
        end,
        desc = " Toggle",
      },
      {
        "<leader>hm",
        function()
          require("telescope").load_extension("harpoon")
        end,
        desc = " Telescope Marks",
      },
    },
  },
}
