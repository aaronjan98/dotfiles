require("core.options")
require("core.keymaps")
require("lazy_setup")

-- Enable treesitter-based highlighting (built into neovim, no plugin config needed)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "lua" },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

if vim.g.neovide then
  vim.g.neovide_cursor_vfx_mode = ""
  vim.g.neovide_cursor_animation_length = 0.13
  vim.g.neovide_cursor_trail_size = 0.8

  local function set_cursor_color()
    vim.api.nvim_set_hl(0, "Cursor", { fg = "#1a0810", bg = "#E62600" })
  end
  set_cursor_color()
  vim.api.nvim_create_autocmd("ColorScheme", { pattern = "*", callback = set_cursor_color })

  vim.opt.guicursor =
    "n-v-c:block-Cursor," ..
    "i-ci-ve:ver25-Cursor," ..
    "r-cr:hor20-Cursor," ..
    "o:hor20-Cursor," ..
    "a:blinkwait500-blinkoff500-blinkon500-Cursor"
end

