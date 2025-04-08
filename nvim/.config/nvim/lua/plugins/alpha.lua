return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    require "alpha.term"
    local dashboard = require "alpha.themes.dashboard"

    local function dashboard_button(sc, txt, keybind)
      local button = dashboard.button(sc, txt, keybind)
      button.opts.hl_shortcut = "AlphaShortcut"
      button.opts.hl = "AlphaButtons"
      return button
    end
    --
    dashboard.section.terminal.command = "cat | ~/.config/nvim/ansi-images/sky.sh"
    dashboard.section.terminal.width = 80
    dashboard.section.terminal.height = 16
    dashboard.section.terminal.opts.redraw = true

    dashboard.section.buttons.val = {
      dashboard_button("f", "  Find file", "<cmd>Telescope find_files<cr>"),
      dashboard_button("r", "  Recent files", "<cmd>Telescope oldfiles only_cwd=true<cr>"),
      dashboard_button("g", "  Grep", "<cmd>Telescope live_grep<cr>"),
      dashboard_button("q", "  Quit", "<cmd>qa<cr>"),
    }
    dashboard.section.buttons.opts.hl = "AlphaButtons"
    dashboard.section.buttons.opts.hl_shortcut = "AlphaShortcut"

    dashboard.config.layout = {
      { type = "padding", val = 1 },
      dashboard.section.terminal,
      { type = "padding", val = 1 },
      dashboard.section.buttons,
    }

    -- print("dashboard.config" .. vim.inspect(dashboard.config))

    require("alpha").setup(dashboard.opts)
  end,
}
