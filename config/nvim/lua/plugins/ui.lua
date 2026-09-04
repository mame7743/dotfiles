return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({})
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "ファイルツリー" })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({})
      require("which-key").add({
        { "<leader>f", group = "検索" },
      })
    end,
  },
}
