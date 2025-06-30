-- lua/plugins/mini-icons.lua
return {
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    local icons = require("mini.icons")

    icons.setup({
      style = "glyph", -- or "ascii" for plain > and +
      default = { highlight = "MiniIconsMono" },
      directory = { highlight = "MiniIconsMono" },
      file = { highlight = "MiniIconsMono" },
      filetype = { highlight = "MiniIconsMono" },
      extension = { highlight = "MiniIconsMono" },
      lsp = { highlight = "MiniIconsMono" },
      os = { highlight = "MiniIconsMono" },
    })

    icons.mock_nvim_web_devicons() -- hand icon data to plugins

    -- single neutral colour = Normal fg (falls back to #a0a8b9)
    local function apply_mono()
      local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
      -- local fg = normal.fg or "#a0a8b9"
      local fg = "#7aa2f7"
      -- every MiniIcons* HL that ships with the plugin
      for _, name in ipairs(vim.fn.getcompletion("MiniIcons", "highlight")) do
        vim.api.nvim_set_hl(0, name, { fg = fg })
      end
      vim.api.nvim_set_hl(0, "MiniIconsMono", { fg = fg })
    end

    -- apply now and after every :colorscheme
    apply_mono()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_mono })
  end,
}
