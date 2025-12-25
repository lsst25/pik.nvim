local M = {}

M.config = {
  cli_path = "pik",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.list_selectors()
  local handle = io.popen(M.config.cli_path .. " list --json 2>/dev/null")
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
  local cmd = string.format("%s set %s %s", M.config.cli_path, selector_name, option_name)
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

  telescope.extensions.pik.pik()
end

return M
