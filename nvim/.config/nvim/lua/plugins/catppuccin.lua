return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "macchiato", -- latte, frappe, macchiato, mocha
    transparent_background = true,
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)

    -- setup must be called before loading
    vim.cmd.colorscheme "catppuccin"
  end,
}
