-- Switch git worktrees (managed by worktrunk's `wt`) without leaving Neovim.
-- <leader>gW opens a Snacks picker fed by `wt list --format=json`; selecting a
-- worktree cd's into it, closes buffers from the old worktree (keeping any
-- with unsaved changes), stops LSP clients rooted in the old worktree, and
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

local function age(timestamp)
  if not timestamp then
    return ""
  end
  local s = os.time() - timestamp
  if s < 3600 then
    return math.floor(s / 60) .. "m"
  elseif s < 86400 then
    return math.floor(s / 3600) .. "h"
  else
    return math.floor(s / 86400) .. "d"
  end
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
  vim.system({ "wt", "list", "--format=json" }, { text = true }, function(out)
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

      local old_root = vim.fn.getcwd()
      local items = {}
      for _, wt in ipairs(worktrees) do
        if wt.kind == "worktree" and wt.path and wt.branch then
          if wt.is_current then
            old_root = wt.path
          end
          items[#items + 1] = { text = wt.branch .. " " .. wt.path, wt = wt }
        end
      end

      Snacks.picker({
        title = "Worktrees",
        layout = { preset = "select" },
        items = items,
        format = function(item)
          local wt = item.wt
          return {
            { wt.is_current and "@ " or "  ", "Special" },
            { ("%-28s"):format(wt.branch), wt.is_current and "Special" or "Normal" },
            { ("%-6s"):format(wt.symbols or ""), "DiagnosticWarn" },
            { ("%4s "):format(age(wt.commit and wt.commit.timestamp)), "Comment" },
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
