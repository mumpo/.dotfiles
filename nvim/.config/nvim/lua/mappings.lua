local map = vim.keymap.set
local function opts(desc)
  return { noremap = true, silent = true, desc = desc }
end

map("n", "mj", ":m .+1<CR>==", opts "Move line down")
map("n", "mk", ":m .-2<CR>==", opts "Move line up")

-- Navigate buffers
map("n", "<S-h>", ":bprevious<CR>", opts "Go to previous buffer")
map("n", "<S-l>", ":bnext<CR>", opts "Go to next buffer")

map("n", "<leader>bo", ":%bd|e#<CR>", opts "Delete all other buffers")

-- Select all
map("n", "<C-a>", "gg<S-v>G", opts "Select all")

-- Terminal
map("t", "<C-z>", "<C-\\><C-n>", opts "Close terminal")

-- Non-destructive paste
map("x", "<leader>p", [["_dP]])

-- Yank to system clipboard
map({ "n", "v" }, "<leader>y", [["+y]])
map("n", "<leader>Y", [["+Y]])
