vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

-- System clipboard (Wayland works via wl-copy installed by Nix)
vim.opt.clipboard = "unnamedplus"

-- Slightly nicer defaults
vim.opt.updatetime = 200
vim.opt.timeoutlen = 400

-- Cursor shape & blinking
vim.opt.guicursor =
  "n-v-c:block," ..
  "i-ci-ve:ver25," ..
  "r-cr:hor20," ..
  "o:hor20," ..
  "a:blinkwait500-blinkoff500-blinkon500"
