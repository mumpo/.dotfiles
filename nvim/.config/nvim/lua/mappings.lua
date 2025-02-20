local map = vim.keymap.set

map("n", "mj", ":m .+1<CR>==", { noremap = true, silent = false })
map("n", "mk", ":m .-2<CR>==", { noremap = true, silent = false })
