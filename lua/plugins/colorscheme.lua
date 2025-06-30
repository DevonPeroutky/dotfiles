-- return {
--   { "thesimonho/kanagawa-paper.nvim" },
--
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       colorscheme = "tokyonight-moon",
--     },
--   },
-- }
--

return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "storm",
      styles = {
        comments = { italic = true }, -- This will be overridden below
        keywords = { italic = true },
        functions = {},
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      on_highlights = function(hl, c)
        -- Function parameters - cyan/teal
        hl["@parameter.builtin"] = { fg = c.fg } -- 'type=' part
        hl["@property"] = { fg = c.fg } -- Alternative for keyword args
        hl["@parameter"] = { fg = c.fg }
        hl["@variable.parameter"] = { fg = c.fg }

        -- Import statements and module names - cyan/teal
        hl["@module"] = { fg = c.fg }
        hl["@namespace"] = { fg = c.fg }

        -- Type annotations - cyan/teal
        hl["@type"] = { fg = c.cyan }
        hl["@type.builtin"] = { fg = c.cyan }
        hl["@type.definition"] = { fg = c.cyan }

        -- Class names - cyan/teal
        hl["@constructor"] = { fg = c.cyan }
        hl["@type.qualifier"] = { fg = c.cyan }

        -- Keywords like 'import', 'from', 'def' - purple
        hl["@keyword"] = { fg = c.purple, italic = true }
        hl["@keyword.import"] = { fg = c.purple, italic = true }
        hl["@keyword.function"] = { fg = c.purple, italic = true }

        -- String literals - green
        hl["@string"] = { fg = c.green }
        hl["@string.documentation"] = { fg = c.green, italic = true } -- Docstrings green

        -- Constants like 'None' - orange
        hl["@constant.builtin"] = { fg = c.orange }
        hl["@variable.builtin"] = { fg = c.orange }

        -- Regular comments - gray
        hl["Comment"] = { fg = c.comment, italic = true }
        hl["@comment"] = { fg = c.comment, italic = true }
        hl["@comment.documentation"] = { fg = c.green, italic = true }

        -- Variable names - default white
        hl["@variable"] = { fg = c.fg }

        -- Function names - blue
        hl["@function"] = { fg = c.blue }
        hl["@function.call"] = { fg = c.blue }
      end,
    },
  },
  -- { "neanias/everforest-nvim" },
  -- { "thesimonho/kanagawa-paper.nvim" },
  -- { "wesenseged/stone.nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-storm",
    },
  },
}
