-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Styling --
-- Remove extra padding in signcolumn
vim.opt.signcolumn = "auto"

vim.opt.fillchars:append({ vert = " " }) -- Use a space instead
vim.opt.fillchars:append({ horiz = " " }) -- Use a space instead
