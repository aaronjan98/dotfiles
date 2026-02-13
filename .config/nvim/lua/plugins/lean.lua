return {
  {
    "Julian/lean.nvim",
    event = { "BufReadPre *.lean", "BufNewFile *.lean" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      mappings = true,
      lsp = {
        on_attach = function(_, bufnr)
          -- optional: buffer-local keymaps go here
        end,
      },
    },
  },
}

