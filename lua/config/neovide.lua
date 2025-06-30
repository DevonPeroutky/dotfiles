-- neovide-config.lua
-- Ensure this file is sourced in your LazyVim config

-- Main font configuration for ASCII characters
vim.o.guifont = "Monaco:h12"

-- Set background to black
vim.g.neovide_opacity = 1.0
vim.g.neovide_background_color = "#000000"

if vim.g.neovide then
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0
end

-- Additional settings for Neovide
vim.g.neovide_floating_blur_amount_x = 100 -- Adjust if blur is needed
vim.g.neovide_floating_blur_amount_y = 100

-- Non-ASCII font configuration (Fallback Font)
vim.g.neovide_fallback_fonts = { "Inconsolata Nerd Font:h12" } -- Fallback for symbols and non-ASCII

-- Enable anti-aliasing (Neovide usually enables this by default)
vim.g.neovide_cursor_antialiasing = true

vim.g.neovide_scale_factor = 1.0
local change_scale_factor = function(delta)
  vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end
vim.keymap.set("n", "<C-=>", function()
  change_scale_factor(1.25)
end)
vim.keymap.set("n", "<C-->", function()
  change_scale_factor(1 / 1.25)
end)

-- Enable pasting
if vim.g.neovide then
  vim.keymap.set("i", "<D-v>", "<C-R>+")
end

-- Open full screen by default
if vim.g.neovide then
  -- Enable full-screen mode on startup
  vim.g.neovide_fullscreen = true

  -- If you want to remember window size and position:
  vim.g.neovide_remember_window_size = true

  -- Optional: Set the initial window size if not using remember_window_size
  -- vim.g.neovide_window_width = 1920
  -- vim.g.neovide_window_height = 1080
end

-- Set option key to be meta
vim.g.neovide_input_macos_option_key_is_meta = "both"

-- To fix the 'pipe' breaks
vim.g.neovide_box_drawing_mode = "native"
