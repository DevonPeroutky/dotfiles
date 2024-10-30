-- return {
--   -- amongst your other plugins
--   -- {'akinsho/toggleterm.nvim', version = "*", config = true}
--   -- or
--   {
--     "akinsho/toggleterm.nvim",
--     version = "*",
--     opts = {
--       direction = "horizontal",
--       size = function()
--         return math.floor(vim.o.lines * 0.3)
--       end,
--     },
--   },
-- }

return {
  {
    "akinsho/toggleterm.nvim",
    config = true,
    cmd = "ToggleTerm",
    -- keys = { { "<F4>", "<cmd>ToggleTerm<cr>", desc = "Toggle floating terminal" } },
    keys = {
      { "<leader>ft", false }, -- Remove default LazyVim terminal keymap
      { "<leader>fT", false }, -- Remove default LazyVim terminal keymap
      { "<leader>ft", "<cmd>ToggleTerm direction=horizontal<cr><cmd>startinsert<cr>", desc = "Terminal (horizontal)" },
    },
    opts = {
      direction = "horizontal",
      size = function()
        return math.floor(vim.o.lines * 0.3)
      end,
    },
  },
}
