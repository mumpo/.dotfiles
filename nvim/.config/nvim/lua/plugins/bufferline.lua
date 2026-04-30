local function fix_transparency()
  local transparent_groups = {
    "TabLine",
    "TabLineFill",
  }

  for _, group in ipairs(transparent_groups) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = fix_transparency,
})

-- Trigger buffer rename when deleting files in oil.nvim
vim.api.nvim_create_autocmd({ "BufWritePost", "BufFilePost", "FileChangedShellPost" }, {
  callback = function()
    vim.cmd.redrawtabline()
  end,
})

return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      diagnostics = "nvim_lsp",
      separator_style = "thin",
      -- Use TabLine highlights instead of BufferLine highlights
      -- I couldn't make the transparency work with BufferLine highlights.
      themable = false,
      name_formatter = function(buf)
        -- Indicate that the file is not saved yet, or has been deleted.
        -- Useful when deleting files in oil.nvim that are still open as buffers.
        if vim.fn.filereadable(buf.path) == 0 then
          return "[?] " .. buf.name
        end
        return buf.name
      end,
    },
  },
}
