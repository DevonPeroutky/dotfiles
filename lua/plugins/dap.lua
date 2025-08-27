return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    recommended = true,
    opts = function()
      local dap = require("dap")
      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 5005, -- check on this for spring
        },
        {
          type = "java",
          request = "launch",
          name = "Debug JUnit Test (Manual)",
          mainClass = "", -- Will be filled dynamically by jdtls
        },
      }
    end,
    keys = function()
      return {
        -- stylua: ignore start
        { "<leader>x", group = "  Debug" },
        { "<leader>xB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition", },
        { "<leader>xb", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint", },
        { "<leader>xc", function() require("dap").continue() end, desc = "Continue", },
        { "<leader>xa", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args", },
        { "<leader>xC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor", },
        { "<leader>xg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)", },
        { "<leader>xi", function() require("dap").step_into() end, desc = "Step Into", },
        { "<leader>xj", function() require("dap").down() end, desc = "Down", },
        { "<leader>xk", function() require("dap").up() end, desc = "Up", },
        { "<leader>xl", function() require("dap").run_last() end, desc = "Run Last", },
        { "<leader>xO", function() require("dap").step_out() end, desc = "Step Out", },
        { "<leader>xo", function() require("dap").step_over() end, desc = "Step Over", },
        { "<leader>xp", function() require("dap").pause() end, desc = "Pause", },
        { "<leader>xr", function() require("dap").repl.toggle() end, desc = "Toggle REPL", },
        { "<leader>xs", function() require("dap").session() end, desc = "Session", },
        { "<leader>xt", function() require("dap").terminate() end, desc = "Terminate", },
        { "<leader>xw", function() require("dap.ui.widgets").hover() end, desc = "Widgets", },
        { "<leader>xPt", function() require("dap-python").test_method() end, desc = "Debug Method", ft = "python", },
        { "<leader>xPc", function() require("dap-python").test_class() end, desc = "Debug Class", ft = "python", },
      }
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = function()
      return {
        -- stylua: ignore start
        { "<leader>xu", function() require("dapui").toggle({}) end, desc = "Dap UI", },
        { "<leader>xe", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" }, },
      }
    end,
        -- stylua: ignore start
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        vim.notify("Debugging Session has Ended", vim.log.levels.INFO, { title = " " })
      end
    end,
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    config = function()
      local function get_python_path()
        -- Check for virtual environment first
        local venv = vim.env.VIRTUAL_ENV
        if venv and venv ~= "" then
          local venv_python = venv .. "/bin/python"
          if vim.fn.executable(venv_python) == 1 then
            return venv_python
          end
        end
        
        -- Fallback to system python
        local python_paths = { "python3", "python" }
        for _, python in ipairs(python_paths) do
          if vim.fn.executable(python) == 1 then
            return python
          end
        end
        
        return "python3"
      end
      
      require("dap-python").setup(get_python_path())
      require("dap-python").test_runner = "pytest"
    end,
  },
}

-- return {
--   "mfussenegger/nvim-dap-python",
--   keys = {
--     -- **Test-Related Key Mappings**
--     {
--       mode = "n",
--       "<leader>dm",
--       function()
--         require("dap-python").test_method()
--       end,
--       desc = "Debug Test Method",
--     },
--     {
--       mode = "n",
--       "<leader>dc",
--       function()
--         require("dap-python").test_class()
--       end,
--       desc = "Debug Test Class",
--     },
--     -- **File-Related Key Mappings**
--     {
--       mode = "n",
--       "<leader>df",
--       function()
--         require("dap-python").debug_file()
--       end,
--       desc = "Debug Python File",
--     },
--
--     -- **Function-Related Key Mappings**
--     {
--       mode = "n",
--       "<leader>du",
--       function()
--         -- Custom function to debug the function under the cursor
--         local dap_python = require("dap-python")
--         local utils = require("dap-python.utils")
--         local path = vim.fn.expand("%:p")
--         local row = vim.fn.line(".")
--         local func_name = utils.get_func_at_line(path, row)
--         if func_name then
--           dap_python.debug_at_point()
--         else
--           print("No function found under cursor.")
--         end
--       end,
--       desc = "Debug Function Under Cursor",
--     },
--
--     -- **Class-Related Key Mappings**
--     {
--       mode = "n",
--       "<leader>dk",
--       function()
--         -- Custom function to debug the class under the cursor
--         local dap_python = require("dap-python")
--         local utils = require("dap-python.utils")
--         local path = vim.fn.expand("%:p")
--         local row = vim.fn.line(".")
--         local class_name = utils.get_class_at_line(path, row)
--         if class_name then
--           dap_python.debug_at_point()
--         else
--           print("No class found under cursor.")
--         end
--       end,
--       desc = "Debug Class Under Cursor",
--     },
--   },
--   config = function()
--     require("dap-python").setup(vim.g.python3_host_prog)
--     require("dap-python").test_runner = "pytest"
--   end,
-- }
-- return {
--   {
--     "mfussenegger/nvim-dap",
--     event = "VeryLazy",
--     dependencies = {
--       "jay-babu/mason-nvim-dap.nvim",
--       "williamboman/mason.nvim",
--       "rcarriga/nvim-dap-ui",
--       "mfussenegger/nvim-dap-python",
--     },
--     config = function()
--       -- Ensure Mason + mason-nvim-dap are set up
--       require("mason").setup()
--       require("mason-nvim-dap").setup({
--         ensure_installed = { "python" },
--         automatic_installation = true,
--       })
--
--       local dap = require("dap")
--       local dapui = require("dapui")
--       dapui.setup()
--
--       -- -------- Python configuration --------
--       local function path_exists(p)
--         return (vim.fn.filereadable(p) == 1) or (vim.fn.isdirectory(p) == 1)
--       end
--
--       local mason_py = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
--       local function get_python()
--         local venv = vim.env.VIRTUAL_ENV
--         if venv and venv ~= "" and path_exists(venv .. "/bin/python") then
--           return venv .. "/bin/python" -- use project venv if available
--         elseif path_exists(mason_py) then
--           return mason_py -- fallback to Mason debugpy
--         end
--         return vim.fn.exepath("python3") or "python3"
--       end
--
--       local dap_python = require("dap-python")
--       dap_python.setup(get_python())
--       dap_python.test_runner = "pytest"
--
--       -- Add custom pytest configurations (preserving defaults from dap-python.setup)
--       table.insert(dap.configurations.python, {
--         type = "python",
--         request = "launch",
--         name = "Pytest: current file (-vv)",
--         module = "pytest",
--         args = function()
--           return { vim.fn.expand("%:p"), "-vv", "-s" }
--         end,
--         python = get_python,
--         console = "integratedTerminal",
--         justMyCode = false,
--         cwd = "${workspaceFolder}",
--       })
--
--       table.insert(dap.configurations.python, {
--         type = "python",
--         request = "launch",
--         name = "Pytest: nodeid (-vv)",
--         module = "pytest",
--         args = function()
--           local default = vim.fn.expand("%:p") .. "::" .. (vim.fn.expand("<cword>") or "")
--           local nodeid = vim.fn.input("pytest nodeid: ", default)
--           return { nodeid, "-vv", "-s" }
--         end,
--         python = get_python,
--         console = "integratedTerminal",
--         justMyCode = false,
--         cwd = "${workspaceFolder}",
--       })
--     end,
--   },
-- }
