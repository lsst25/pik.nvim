local M = {}

M.config = {
  cli_path = "pik",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- Select plugin functions

function M.list_selectors()
  local handle = io.popen(M.config.cli_path .. " select list --json 2>/dev/null")
  if not handle then
    return nil, "Failed to execute pik"
  end

  local result = handle:read("*a")
  handle:close()

  if result == "" then
    return nil, "No output from pik CLI"
  end

  local ok, data = pcall(vim.json.decode, result)
  if not ok then
    return nil, "Failed to parse JSON: " .. result
  end

  if data.error then
    return nil, data.error
  end

  return data, nil
end

function M.set_option(selector_name, option_name)
  local cmd = string.format("%s select set %s %s", M.config.cli_path, selector_name, option_name)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return false, "Failed to execute pik"
  end

  local result = handle:read("*a")
  local success = handle:close()

  if not success then
    return false, result
  end

  return true, result
end

function M.switch()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is required for pik.switch()", vim.log.levels.ERROR)
    return
  end

  telescope.extensions.pik.select()
end

-- Worktree plugin functions

function M.list_worktrees()
  local handle = io.popen(M.config.cli_path .. " worktree list --json 2>/dev/null")
  if not handle then
    return nil, "Failed to execute pik"
  end

  local result = handle:read("*a")
  handle:close()

  if result == "" then
    return nil, "No output from pik CLI (worktree plugin may not be configured)"
  end

  local ok, data = pcall(vim.json.decode, result)
  if not ok then
    return nil, "Failed to parse JSON: " .. result
  end

  return data, nil
end

function M.list_branches()
  local handle = io.popen("git branch --format='%(refname:short)' 2>/dev/null")
  if not handle then
    return nil, "Failed to execute git"
  end

  local result = handle:read("*a")
  handle:close()

  local branches = {}
  for branch in result:gmatch("[^\r\n]+") do
    table.insert(branches, branch)
  end

  return branches, nil
end

function M.switch_worktree(path)
  local ok, err = pcall(vim.cmd, "cd " .. vim.fn.fnameescape(path))
  if not ok then
    return false, "Failed to change directory: " .. (err or "unknown error")
  end

  return true, nil
end

function M.create_worktree(branch, is_new_branch, worktree_name)
  local args = "worktree create"
  if worktree_name then
    args = args .. " " .. vim.fn.shellescape(worktree_name)
  end
  args = args .. " -b " .. vim.fn.shellescape(branch)
  if is_new_branch then
    args = args .. " -n"
  end

  local cmd = M.config.cli_path .. " " .. args .. " 2>&1"
  local handle = io.popen(cmd)
  if not handle then
    return false, "Failed to execute pik"
  end

  local result = handle:read("*a")
  local success = handle:close()

  if not success then
    return false, result
  end

  return true, result
end

function M.remove_worktree(path, force)
  local args = "worktree remove"
  if force then
    args = args .. " -f"
  end
  args = args .. " " .. vim.fn.shellescape(path)

  local cmd = M.config.cli_path .. " " .. args .. " 2>&1"
  local handle = io.popen(cmd)
  if not handle then
    return false, "Failed to execute pik"
  end

  local result = handle:read("*a")
  local success = handle:close()

  if not success then
    return false, result
  end

  return true, result
end

function M.worktree()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is required for pik.worktree()", vim.log.levels.ERROR)
    return
  end

  telescope.extensions.pik.worktree()
end

function M.worktree_create()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is required for pik.worktree_create()", vim.log.levels.ERROR)
    return
  end

  telescope.extensions.pik.worktree_create()
end

function M.worktree_remove()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is required for pik.worktree_remove()", vim.log.levels.ERROR)
    return
  end

  telescope.extensions.pik.worktree_remove()
end

return M
