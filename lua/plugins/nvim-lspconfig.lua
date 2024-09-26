return {
  "neovim/nvim-lspconfig",
  opts = {
    diagnostics = {
      -- virtual_text = false,
      virtual_text = false,
      signs = false,
      -- virtual_text = {
      --   spacing = 4,
      --   source = "if_many",
      --   prefix = "●",
      --   -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
      --   -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
      --   -- prefix = "icons",
      -- },
      --         virtual_text = false,
    },
    servers = {
      ruff = {
        mason = false,
        enabled = false,
      },
      tailwindcss = {
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                { "cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                { 'cls="([^"]*)"' },
                { "([a-zA-Z0-9\\-:]+)" },
              },
            },
          },
        },
        -- exclude a filetype from the default_config
        filetypes_exclude = { "" },
        -- add additional filetypes to the default_config
        filetypes_include = { "python" },
      },
    },
  },
}
