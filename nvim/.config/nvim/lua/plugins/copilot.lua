return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  options = {
    panel = {
      keymap = {
        open = "<M-.>",
      },
    },
  },
  config = function(_, opts)
    require("copilot").setup(opts)
  end,
}
