return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local t = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", t.find_files, { desc = "ファイル検索" })
      vim.keymap.set("n", "<leader>fg", t.live_grep, { desc = "grep検索" })
      vim.keymap.set("n", "<leader>fb", t.buffers, { desc = "バッファ一覧" })
    end,
  },
}
