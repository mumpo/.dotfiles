return {
  -- mini.ai: Smart text objects and motions
  {
    "echasnovski/mini.ai",
    event = "BufReadPre",
    dependencies = "nvim-treesitter/nvim-treesitter-textobjects",
    opts = function()
      local miniai = require "mini.ai"

      return {
        custom_textobjects = {
          f = miniai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
        },
      }
    end,
  },
}
