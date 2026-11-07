-- Switch git worktrees (managed by worktrunk's `wt`) without leaving Neovim.
-- <leader>gW (Space, g, Shift+W) opens a Snacks picker fed by
-- `wt list --format=json`; selecting a worktree changes directory into it,
-- closes buffers from the old worktree (keeping unsaved changes),
-- stops LSP clients rooted in the old worktree, and
-- reopens the current file at the same relative path if it exists there.

-- Returns path relative to root ("" if path == root), or nil if not under root
local function relpath(path, root)
  root = root:gsub("/+$", "")
  if path == root then
    return ""
  end
  if path:sub(1, #root + 1) == root .. "/" then
    return path:sub(#root + 2)
  end
  return nil
end

local function switch(worktree, old_root)
  local new_root = worktree.path
  if new_root == old_root then
    return
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local rel = current_file ~= "" and relpath(current_file, old_root) or nil

  vim.cmd.cd(vim.fn.fnameescape(new_root))

  -- Open the counterpart of the current file before deleting old buffers, so
  -- the window never lands on a buffer we're about to wipe
  local counterpart = rel and rel ~= "" and (new_root .. "/" .. rel) or nil
  if counterpart and vim.uv.fs_stat(counterpart) then
    vim.cmd.edit(vim.fn.fnameescape(counterpart))
  else
    vim.cmd.enew()
  end

  local kept = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and relpath(name, old_root) then
        if vim.bo[buf].modified then
          kept = kept + 1
        else
          pcall(vim.api.nvim_buf_delete, buf, {})
        end
      end
    end
  end

  for _, client in ipairs(vim.lsp.get_clients()) do
    local root = client.config and client.config.root_dir
    if root and relpath(root, old_root) then
      client:stop()
    end
  end

  local msg = "Switched to worktree " .. (worktree.branch or new_root)
  if kept > 0 then
    msg = msg .. (" (%d modified buffer%s kept)"):format(kept, kept > 1 and "s" or "")
  end
  vim.notify(msg, vim.log.levels.INFO, { title = "worktrunk" })
end

local function pick_worktree()
  if vim.fn.executable("wt") ~= 1 then
    vim.notify("Worktrunk (`wt`) is not on PATH", vim.log.levels.ERROR, { title = "worktrunk" })
    return
  end

  local cwd = vim.fn.getcwd()
  vim.system({ "wt", "list", "--format=json" }, { text = true, cwd = cwd }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        vim.notify("wt list failed:\n" .. (out.stderr or ""), vim.log.levels.ERROR, { title = "worktrunk" })
        return
      end
      local ok, worktrees = pcall(vim.json.decode, out.stdout)
      if not ok or type(worktrees) ~= "table" then
        vim.notify("Could not parse `wt list` output", vim.log.levels.ERROR, { title = "worktrunk" })
        return
      end

      local old_root = cwd
      local items = {}
      -- Schema 2 wraps rows in `items`; schema 1 returned a bare array.
      for _, row in ipairs(worktrees.items or worktrees) do
        local wt
        if type(row.worktree) == "table" and row.worktree.path then
          wt = {
            path = row.worktree.path,
            branch = type(row.branch) == "string" and row.branch or (row.head or {}).short_sha or "(detached)",
            is_current = row.worktree.current,
            symbols = (row.display or {}).symbols,
            commit = { short_sha = (row.head or {}).short_sha, message = (row.head or {}).subject },
          }
        elseif row.kind == "worktree" and row.path then
          wt = row
        end
        if wt then
          wt.branch = type(wt.branch) == "string" and wt.branch or (wt.commit or {}).short_sha or "(detached)"
          if wt.is_current then
            old_root = wt.path
          end
          items[#items + 1] = { text = wt.branch .. " " .. wt.path, wt = wt }
        end
      end
      if #items == 0 then
        vim.notify("No worktrees found", vim.log.levels.WARN, { title = "worktrunk" })
        return
      end

      -- Share display-cell widths between the fixed header and every result.
      local widths = { branch = 28, status = 6, commit = 7 }
      for _, item in ipairs(items) do
        local wt = item.wt
        widths.branch = math.max(widths.branch, vim.fn.strdisplaywidth(wt.branch))
        widths.status = math.max(widths.status, vim.fn.strdisplaywidth(wt.symbols or ""))
        widths.commit = math.max(widths.commit, vim.fn.strdisplaywidth((wt.commit or {}).short_sha or ""))
      end
      local function column(text, width)
        return text .. string.rep(" ", width - vim.fn.strdisplaywidth(text)) .. " "
      end
      -- Snacks adds one leading cell to each row, followed by our two-cell marker.
      local header = "   " .. column("Branch", widths.branch) .. column("Status", widths.status)
        .. column("Commit", widths.commit) .. "Message"

      Snacks.picker({
        title = "Worktrees",
        layout = { preset = "select" },
        items = items,
        win = { list = { wo = { winbar = "%#Title#" .. header .. "%*" } } },
        format = function(item)
          local wt = item.wt
          return {
            { wt.is_current and "@ " or "  ", "Special" },
            { column(wt.branch, widths.branch), wt.is_current and "Special" or "Normal" },
            { column(wt.symbols or "", widths.status), "DiagnosticWarn" },
            { column(wt.commit and wt.commit.short_sha or "", widths.commit), "Comment" },
            { wt.commit and wt.commit.message or "", "Comment" },
          }
        end,
        confirm = function(picker, item)
          picker:close()
          if item then
            switch(item.wt, old_root)
          end
        end,
      })
    end)
  end)
end

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>gW", pick_worktree, desc = "Worktrees (worktrunk)" },
  },
  init = function()
    vim.api.nvim_create_user_command("WorktreeSwitch", pick_worktree, { desc = "Switch git worktree via worktrunk" })
  end,
}
