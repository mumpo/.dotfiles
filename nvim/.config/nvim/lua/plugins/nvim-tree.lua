local FLOAT_HEIGHT_RATIO = 0.8
local FLOAT_WIDTH_RATIO = 0.6

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
    filters = {
      custom = { "^.git$" },
      git_ignored = false,
    },
    view = {
      float = {
        enable = true,
        open_win_config = function()
          local screen_w = vim.opt.columns:get()
          local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
          local window_w = screen_w * FLOAT_WIDTH_RATIO
          local window_h = screen_h * FLOAT_HEIGHT_RATIO
          local window_w_int = math.floor(window_w)
          local window_h_int = math.floor(window_h)
          local center_x = (screen_w - window_w) / 2
          local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
          return {
            border = "rounded",
            relative = "editor",
            row = center_y,
            col = center_x,
            width = window_w_int,
            height = window_h_int,
          }
        end,
      },
      width = function()
        return math.floor(vim.opt.columns:get() * FLOAT_WIDTH_RATIO)
      end,
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
    { "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle file tree" },
  },
  config = function(_, opts)
    local nvim_tree = require "nvim-tree"
    nvim_tree.setup(opts)

    local api = require "nvim-tree.api"
    api.events.subscribe(api.events.Event.FileCreated, function(file)
      vim.cmd("edit " .. vim.fn.fnameescape(file.fname))
    end)
  end,
}
