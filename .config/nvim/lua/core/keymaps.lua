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

local function hypr_focus(dir)
  -- only attempt if hyprctl exists
  if vim.fn.executable("hyprctl") ~= 1 then return end
  vim.fn.system({ "hyprctl", "dispatch", "movefocus", dir })
end

local function smart_nav(dir, tmux_cmd)
  return function()
    local win_before = vim.api.nvim_get_current_win()
    vim.cmd(tmux_cmd)
    vim.schedule(function()
      local win_after = vim.api.nvim_get_current_win()
      if win_after == win_before then
        -- didn't move inside vim/tmux, so try Hyprland
        hypr_focus(dir)
      end
    end)
  end
end

map("n", "<M-H>", smart_nav("l", "TmuxNavigateLeft"), opts)
map("n", "<M-J>", smart_nav("d", "TmuxNavigateDown"), opts)
map("n", "<M-K>", smart_nav("u", "TmuxNavigateUp"), opts)
map("n", "<M-L>", smart_nav("r", "TmuxNavigateRight"), opts)

-- Save
map("n", "<C-s>", ":w<CR>", opts)

