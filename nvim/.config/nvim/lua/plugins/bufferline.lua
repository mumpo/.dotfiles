return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      diagnostics = "nvim_lsp",
      separator_style = "thin",
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          text_align = "left",
          separator = true,
        },
      },
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)

    vim.keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
    vim.keymap.set("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
  end,
}
