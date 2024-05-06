return {
  "catppuccin/nvim",
  priority = 1000,
  lazy = false,
  name = "catppuccin",
  config = function()
    require("catppuccin").setup({
      flavour = "latte", -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = "latte",
        dark = "mocha",
      },
      term_colors = false,
      integrations = {
        neotree = true,
        treesitter = true,
        treesitter_context = true,
        telescope = {
          enabled = true,
          style = "nvchad",
        },
      }
    })

    vim.api.nvim_command("colorscheme catppuccin")
  end,
}
