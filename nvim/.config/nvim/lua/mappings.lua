require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "mj", ":m .+1<CR>==", { noremap = true, silent = false })
map("n", "mk", ":m .-2<CR>==", { noremap = true, silent = false })
