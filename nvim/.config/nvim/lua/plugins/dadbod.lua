return {
  "tpope/vim-dadbod",
  dependencies = {
    { "kristijanhusak/vim-dadbod-ui", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", lazy = true },
  },
  keys = {
    {
      "<leader>bt",
      "<cmd>DBUIToggle<cr>",
      desc = "Toggle Database UI",
    },
  },
}
