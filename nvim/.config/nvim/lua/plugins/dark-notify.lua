return {
  "cormacrelf/dark-notify",
  lazy = false,
  config = function()
    local dn = require "dark_notify"

    dn.run {
      schemes = {
        dark = "catppuccin",
        light = "github_light",
      },
    }
  end,
}
