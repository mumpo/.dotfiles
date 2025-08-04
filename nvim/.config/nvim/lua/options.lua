local o = vim.o
local opt = vim.opt

o.number = true -- Line numbers
o.relativenumber = true -- Enable relative numbers

opt.tabstop = 2
opt.smartindent = true
opt.shiftwidth = 2
opt.expandtab = true

-- Disable swap files
o.swapfile = false
