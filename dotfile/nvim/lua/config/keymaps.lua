local map = vim.keymap.set

map({ "n", "x" }, "<Space>", "<Nop>", { silent = true, desc = "Disable Space movement" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
