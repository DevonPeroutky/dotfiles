return {
  "zbirenbaum/copilot.lua",
  event = "InsertEnter",
  opts = {
    suggestion = {
      enabled = false, -- Enable inline suggestions if you prefer
      -- auto_trigger = true,
      -- keymap = {
      --   accept = "<C-l>",  -- Custom accept keymap
      --   next = "<M-]>",
      --   prev = "<M-[>",
      -- },
    },
    panel = {
      enabled = false, -- Enable the Copilot panel
    },
    filetypes = {
      ["*"] = true, -- default allow
      [""] = false, -- no unnamed/scratch
      markdown = false,
      gitcommit = true,
      help = false,
      lazy = false,
      mason = false,
      ["neo-tree"] = false,
      TelescopePrompt = false,
      ["dap-repl"] = false,
      ["dapui_watches"] = false,
      ["dapui_stacks"] = false,
      ["dapui_scopes"] = false,
      ["dapui_console"] = false,
      ["oil"] = false,
      ["qf"] = false,
      ["starter"] = false,
      -- Add more filetypes as needed
    },
  },
}
