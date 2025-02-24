local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "mj", ":m .+1<CR>==", opts)
map("n", "mk", ":m .-2<CR>==", opts)

-- Navigate buffers
map("n", "<S-h>", ":bprevious<CR>", opts)
map("n", "<S-l>", ":bnext<CR>", opts)
