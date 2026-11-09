return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    local pattern = "~/.config/herdr/plugins/github-installations/vim-herdr-navigation-*/*/checkout/editor/nvim.lua"
    local matches = vim.fn.glob(vim.fn.expand(pattern), false, true)
    if #matches > 0 then
      dofile(matches[#matches])
    end
  end,
}
