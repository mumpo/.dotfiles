return {
  "akinsho/toggleterm.nvim",
  keys = function()
    local runTermCmd = function(cmd)
      return function()
        local Terminal = require("toggleterm.terminal").Terminal
        Terminal:new({ cmd = cmd, hidden = true, direction = "float" }):toggle()
      end
    end

    return {
      {
        "<leader>ld",
        runTermCmd "lazydocker",
        desc = "Open lazydocker",
      },
      {
        "<leader>lg",
        runTermCmd "lazygit",
        desc = "Open lazygit",
      },
      {
        "<leader>lG",
        runTermCmd "gh dash",
        desc = "Open Github dashboard",
      },
    }
  end,
}
