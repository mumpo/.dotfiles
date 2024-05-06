local opts = { noremap = true, silent = true }
local map = vim.keymap.set

-- Navigate buffers
map("n", "<Right>", ":bnext<CR>", opts)
map("n", "<Left>", ":bprevious<CR>", opts)
