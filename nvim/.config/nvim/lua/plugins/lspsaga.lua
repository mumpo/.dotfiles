return {
  "nvimdev/lspsaga.nvim",
  event = "LspAttach",
  opts = {
    crumbs = {
      -- I'm only interested in the breadcrumbs feature
      enable = true,
    },
    lightbulb = {
      enable = false,
    },
    beacon = {
      enable = false,
    },
  },
  keys = {
    { "<leader>rn", "<cmd>Lspsaga rename<cr>", desc = "Rename with LSP", mode = "v" },
  },
}
