local map = vim.keymap.set

map("n", "<leader>w", "<cmd>w<cr>", { desc = "保存" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "終了" })
map("n", "<esc><esc>", "<cmd>nohlsearch<cr>", { desc = "ハイライト解除" })

map("n", "<C-h>", "<C-w>h", { desc = "左の分割へ" })
map("n", "<C-j>", "<C-w>j", { desc = "下の分割へ" })
map("n", "<C-k>", "<C-w>k", { desc = "上の分割へ" })
map("n", "<C-l>", "<C-w>l", { desc = "右の分割へ" })
