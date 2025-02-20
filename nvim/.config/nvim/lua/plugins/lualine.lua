return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup {
      options = {
        globalstatus = true, -- show line below file explorer
        theme = bubbles_theme,
        component_separators = "",
        section_separators = { left = "", right = "" },
        disabled_filetypes = { "NvimTree" },
      },
      sections = {
        lualine_a = { { "mode", right_padding = 2 } },
        lualine_b = { "filename" },
        lualine_c = {
          "branch",
          {
            "diagnostics",
            symbols = {
              error = "",
              warn = "",
              info = "",
              hint = "",
            },
          },
        },
        lualine_x = {},
        lualine_y = { "filetype" },
        lualine_z = {
          { "location", left_padding = 2 },
        },
      },
      inactive_sections = {
        lualine_a = { "filename" },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { "location" },
      },
      tabline = {},
      extensions = {},
    }
  end,
}
