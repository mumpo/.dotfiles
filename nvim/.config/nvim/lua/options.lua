local o = vim.o
local opt = vim.opt

o.number = true -- Line numbers
o.relativenumber = true -- Enable relative numbers

opt.tabstop = 2
opt.smartindent = true
opt.shiftwidth = 2
opt.expandtab = true

-- Allow files to customise editor settings in comments
opt.modeline = true

-- Disable swap files
o.swapfile = false

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.lsp.foldexpr()"
vim.opt.foldlevelstart = 99 -- Start with all folds open
