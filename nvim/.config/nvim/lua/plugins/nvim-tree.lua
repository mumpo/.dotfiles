return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    disable_netrw = true,
    hijack_cursor = true,
    update_focused_file = {
      enable = true,
      update_root = false,
    },
    view = {
      width = 30,
      preserve_window_proportions = true,
    },
    renderer = {
      root_folder_label = false,
      highlight_git = true,
      indent_markers = { enable = true },
      icons = {
        glyphs = {
          default = "󰈚",
          folder = {
            default = "",
            empty = "",
            empty_open = "",
            open = "",
            symlink = "",
          },
          git = { unmerged = "" },
        },
      },
    },
  },
  keys = {
    { "<leader>e", ":NvimTreeFindFileToggle<CR>", desc = "Toggle file tree" },
  },
}
