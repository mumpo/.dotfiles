return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.6',
    cmd = 'Telescope',
    keys = {
      {
        "<C-p>",
        "<cmd>Telescope find_files<CR>",
        desc = "Find files",
      },
      {
        "<leader>fg",
        "<cmd>Telescope live_grep<CR>",
        desc = "Grep files",
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim'
    },
}
