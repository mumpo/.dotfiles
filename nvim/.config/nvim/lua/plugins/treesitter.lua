local languages = {
  "bash",
  "go",
  "gomod",
  "hcl",
  "http",
  "javascript",
  "json",
  "lua",
  "markdown",
  "regex",
  "terraform",
  "tsx",
  "typescript",
  "vim",
  "yaml",
}

local filetypes = {
  "typescriptreact",
}
vim.list_extend(filetypes, languages)

vim.api.nvim_create_autocmd("FileType", {
  pattern = filetypes,
  callback = function()
    vim.treesitter.start()
  end,
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    branch = "main",
    build = ":TSUpdate",
    config = function()
      local treesitter = require "nvim-treesitter"
      treesitter.setup()

      treesitter.install(languages)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
  },
}
