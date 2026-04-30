local map = vim.keymap.set
local function opts(desc)
  return { noremap = true, silent = true, desc = desc }
end

map("n", "mj", ":m .+1<CR>==", opts "Move line down")
map("n", "mk", ":m .-2<CR>==", opts "Move line up")

-- Navigate buffers
map("n", "<S-h>", ":bprevious<CR>", opts "Go to previous buffer")
map("n", "<S-l>", ":bnext<CR>", opts "Go to next buffer")

-- Close all buffers except the current one.
-- We use a custom command instead of `:%bd|e#` to avoid alpha dashboard creating a new empty buffer after closing all buffers.
vim.api.nvim_create_user_command("BufOnly", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end, {})

map("n", "<leader>bo", ":BufOnly<CR>", opts "Delete all other buffers")

-- Select all
map("n", "<C-a>", "gg<S-v>G", opts "Select all")

-- Terminal
map("t", "<C-z>", "<C-\\><C-n>", opts "Close terminal")

-- Non-destructive paste
map("x", "<leader>p", [["_dP]])

-- Yank to system clipboard
map({ "n", "v" }, "<leader>y", [["+y]])
map("n", "<leader>Y", [["+Y]])

-- Open Claude code in a tmux pane
map("n", "<leader>cc", "<cmd>!tmux split-window -h -l 90 'claude'<CR>", opts "Open Claude in tmux")
