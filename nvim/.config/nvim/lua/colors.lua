local highlights = {
  WinBarSep = { bg = "#000000" },
}

local function set()
  for group, args in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, args)
  end
end

set()
