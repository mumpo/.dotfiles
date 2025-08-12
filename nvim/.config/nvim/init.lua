--vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

-- load options
require "options"

-- load plugins
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
}, {})

vim.schedule(function()
  require "mappings"
end)

-- Until Nvim 0.11.0 is released, quickfix
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.http",
  command = "set filetype=http",
})
