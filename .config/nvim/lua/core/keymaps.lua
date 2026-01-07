local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- -------------------------
-- Buffer navigation (s held = Alt)
-- -------------------------
map("n", "<M-j>", ":bnext<CR>", opts)
map("n", "<M-k>", ":bprevious<CR>", opts)

-- -------------------------
-- Tab navigation (s held = Alt)
-- -------------------------
map("n", "<M-h>", ":tabprevious<CR>", opts)
map("n", "<M-l>", ":tabnext<CR>", opts)

-- -------------------------
-- Pane navigation across Neovim splits AND tmux panes (f held = Ctrl+Alt)
-- Requires vim-tmux-navigator plugin
-- -------------------------
map("n", "<M-H>", ":TmuxNavigateLeft<CR>", opts)
map("n", "<M-J>", ":TmuxNavigateDown<CR>", opts)
map("n", "<M-K>", ":TmuxNavigateUp<CR>", opts)
map("n", "<M-L>", ":TmuxNavigateRight<CR>", opts)

-- Save
map("n", "<C-s>", ":w<CR>", opts)

