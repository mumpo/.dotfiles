return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local dashboard = require "alpha.themes.dashboard"

    local function dashboard_button(sc, txt, keybind)
      local button = dashboard.button(sc, txt, keybind)
      button.opts.hl_shortcut = "AlphaShortcut"
      button.opts.hl = "AlphaButtons"
      return button
    end
    dashboard.section.buttons.val = {
      dashboard_button("f", "  Find file", "<cmd>Telescope find_files<cr>"),
      dashboard_button("r", "  Recent files", "<cmd>Telescope oldfiles<cr>"),
      dashboard_button("g", "  Grep", "<cmd>Telescope live_grep<cr>"),
      dashboard_button("q", "  Quit", "<cmd>qa<cr>"),
      { type = "padding", val = 2 },
    }
    dashboard.section.buttons.opts.hl = "AlphaButtons"
    dashboard.opts.layout[1].val = #dashboard.section.buttons.val

    require("alpha").setup(dashboard.opts)
  end,
}
