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
    priority = 1000, -- Ensure this loads before other dap-python configs
    keys = {
      { "<leader>dPt", function() require("dap-python").test_method() end, desc = "Debug Method" },
      { "<leader>dPc", function() require("dap-python").test_class() end, desc = "Debug Class" },
      { "<leader>dpi", "<cmd>DapPythonInfo<cr>", desc = "Python Environment Info" },
    },
    config = function()
      -- Robust Python path detection with environment identification
      local function get_python_info()
        local mason_py = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
        local function path_exists(p)
          return vim.fn.executable(p) == 1
        end

        -- Priority 1: Active virtual environment
        local venv = vim.env.VIRTUAL_ENV
        if venv and venv ~= "" then
          local venv_python = venv .. "/bin/python"
          if path_exists(venv_python) then
            return { path = venv_python, source = "Virtual Environment", venv_path = venv }
          end
        end

        -- Priority 2: Mason debugpy
        if path_exists(mason_py) then
          return { path = mason_py, source = "Mason", venv_path = nil }
        end

        -- Priority 3: System Python
        local python_paths = { "python3", "python" }
        for _, python in ipairs(python_paths) do
          if path_exists(python) then
            local full_path = vim.fn.exepath(python)
            return { path = full_path, source = "System", venv_path = nil }
          end
        end

        -- Fallback
        return { path = "python3", source = "Fallback", venv_path = nil }
      end

      -- Global function for inspection command
      _G.dap_python_info = get_python_info

      local python_info = get_python_info()
      require("dap-python").setup(python_info.path)
      require("dap-python").test_runner = "pytest"

      -- Create custom command to inspect Python environment
      vim.api.nvim_create_user_command("DapPythonInfo", function()
        local info = get_python_info()
        local lines = {
          "DAP Python Environment:",
          "├─ Source: " .. info.source,
          "├─ Path: " .. info.path,
        }

        if info.venv_path then
          table.insert(lines, "├─ Virtual Env: " .. info.venv_path)
        end

        -- Check pytest availability
        local pytest_check =
          vim.fn.system(info.path .. " -c \"import pytest; print('pytest', pytest.__version__)\" 2>/dev/null")
        if vim.v.shell_error == 0 then
          local version = pytest_check:match("pytest%s+([%d%.]+)")
          table.insert(lines, "├─ Pytest: ✓ Available" .. (version and (" (v" .. version .. ")") or ""))
        else
          table.insert(lines, "├─ Pytest: ✗ Not available")
        end

        table.insert(lines, "└─ Active VIRTUAL_ENV: " .. (vim.env.VIRTUAL_ENV or "None"))

        local content = table.concat(lines, "\n")
        vim.notify(content, vim.log.levels.INFO, { title = "🐍 DAP Python Info" })
      end, {
        desc = "Show DAP Python environment information",
      })
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
