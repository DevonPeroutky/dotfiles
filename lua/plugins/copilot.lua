return {
  "zbirenbaum/copilot.lua",
  opts = {
    suggestion = {
      enabled = true, -- Enable inline suggestions if you prefer
      -- auto_trigger = true,
      -- keymap = {
      --   accept = "<C-l>",  -- Custom accept keymap
      --   next = "<M-]>",
      --   prev = "<M-[>",
      -- },
    },
    panel = {
      enabled = true, -- Enable the Copilot panel
    },
    filetypes = {
      markdown = false,
      help = true,
      -- Add more filetypes as needed
    },
  },
}
