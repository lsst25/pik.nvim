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

function M.switch_worktree(path)
  -- Change neovim's working directory
  local ok, err = pcall(vim.cmd, "cd " .. vim.fn.fnameescape(path))
  if not ok then
    return false, "Failed to change directory: " .. (err or "unknown error")
  end

  return true, nil
end

function M.worktree()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is required for pik.worktree()", vim.log.levels.ERROR)
    return
  end

  telescope.extensions.pik.worktree()
end

return M
