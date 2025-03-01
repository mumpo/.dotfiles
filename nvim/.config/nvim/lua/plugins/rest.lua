-- Set the json formatter as jq to pretty print JSON responses
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function(ev)
    vim.bo[ev.buf].formatprg = "jq"
  end,
})

return {
  "rest-nvim/rest.nvim",
  keys = {
    { "<leader>rr", "<cmd>Rest run<CR>", desc = "Run closest request" },
    { "<leader>ro", "<cmd>Rest open<CR>", desc = "Open requests panel" },
    { "<leader>rl", "<cmd>Rest last<CR>", desc = "Run last request" },
    { "<leader>re", "<cmd>Rest env select<CR>", desc = "Select .env file for request file" },
  },
}
