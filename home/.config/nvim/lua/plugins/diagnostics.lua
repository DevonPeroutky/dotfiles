return {
  {
    -- this plugin is already in LazyVim; we’re just tweaking its opts
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- Don't show persistent diagnostics label.
        virtual_text = false,
        -- keep signs / underlines etc. as you like
        update_in_insert = false,
      },
    },
  },
}
