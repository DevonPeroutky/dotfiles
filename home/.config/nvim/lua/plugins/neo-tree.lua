-- ~/.config/nvim/lua/plugins/neo-tree.lua
-- Override the default LazyVim neo-tree configuration

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      -- Remove window borders
      popup = {
        border = "none", -- Remove popup borders
      },
    },
    default_component_configs = {
      icon = { highlight = "MiniIconsMono" }, -- use the mono group
      git_status = { symbols = {} }, -- hide +/?/M letters
      diagnostics = { symbols = {} }, -- hide / icons

      -- remove git letters (+, M, …)
      git_status = {
        symbols = { added = "", modified = "", deleted = "", renamed = "" },
      },

      -- hide diagnostic  /  etc.
      diagnostics = {
        symbols = { hint = "", info = "", warn = "", error = "" },
      },
    },
  },
}
