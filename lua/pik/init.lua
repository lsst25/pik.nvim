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

-- Profile functions

function M.list_profiles()
  local handle = io.popen(M.config.cli_path .. " select profiles --json 2>/dev/null")
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

function M.apply_profile(profile_name)
  local cmd = string.format("%s select profile %s", M.config.cli_path, vim.fn.shellescape(profile_name))
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

function M.profile()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is required for pik.profile()", vim.log.levels.ERROR)
    return
  end

  telescope.extensions.pik.profile()
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

-- Helper function to create output window
local function create_output_window(title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "pikoutput")
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set buffer to be closable with 'q'
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })

  return buf, win
end

function M.create_worktree(branch, is_new_branch, worktree_name, callback)
  local args = "worktree create"
  if worktree_name then
    args = args .. " " .. vim.fn.shellescape(worktree_name)
  end
  args = args .. " -b " .. vim.fn.shellescape(branch)
  if is_new_branch then
    args = args .. " -n"
  end
  args = args .. " -y"

  local cmd = M.config.cli_path .. " " .. args

  -- Create output window
  local buf, win = create_output_window(" Creating Worktree: " .. branch .. " ")
  local output_lines = {}

  local function append_output(job_id, data, event)
    if data then
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(output_lines, line)
        end
      end
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)
          -- Auto-scroll to bottom
          if vim.api.nvim_win_is_valid(win) then
            local line_count = #output_lines
            if line_count > 0 then
              vim.api.nvim_win_set_cursor(win, { line_count, 0 })
            end
          end
        end
      end)
    end
  end

  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = append_output,
    on_stderr = append_output,
    on_exit = function(job_id, exit_code, event)
      vim.schedule(function()
        -- Add completion message
        local final_line = exit_code == 0 and "✓ Worktree created successfully. Press 'q' to close."
          or "✗ Failed to create worktree. Press 'q' to close."
        table.insert(output_lines, "")
        table.insert(output_lines, final_line)

        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_cursor(win, { #output_lines, 0 })
          end
        end

        -- Call callback if provided
        if callback then
          local success = exit_code == 0
          local result = table.concat(output_lines, "\n")
          callback(success, result)
        end
      end)
    end,
  })

  if job_id <= 0 then
    if callback then
      callback(false, "Failed to start job")
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
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

-- Killport plugin functions

function M.kill_port(port)
  local handle = io.popen(string.format("lsof -ti:%d 2>/dev/null", port))
  if not handle then
    return false, "Failed to execute lsof"
  end

  local result = handle:read("*a")
  handle:close()

  local pids = {}
  for pid in result:gmatch("%d+") do
    table.insert(pids, pid)
  end

  if #pids == 0 then
    return false, "No process found on port " .. port
  end

  for _, pid in ipairs(pids) do
    os.execute("kill -9 " .. pid)
  end

  return true, string.format("Killed %d process(es) on port %d", #pids, port)
end

function M.get_killport_config()
  local handle = io.popen(M.config.cli_path .. " killport --config --json 2>/dev/null")
  if not handle then
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  if result == "" then
    return nil
  end

  local ok, data = pcall(vim.json.decode, result)
  if not ok then
    return nil
  end

  return data
end

function M.killport()
  local config = M.get_killport_config()
  local default_port = config and config.defaultPort
  local prompt = "Port number: "
  if default_port then
    prompt = string.format("Port number [%d]: ", default_port)
  end

  vim.ui.input({ prompt = prompt }, function(port_str)
    if port_str == nil then
      return
    end

    if port_str == "" and default_port then
      port_str = tostring(default_port)
    end

    local port = tonumber(port_str)
    if not port or port < 1 or port > 65535 then
      vim.notify("Invalid port number", vim.log.levels.ERROR)
      return
    end

    local success, result = M.kill_port(port)
    if success then
      vim.notify(result, vim.log.levels.INFO)
    else
      vim.notify(result, vim.log.levels.WARN)
    end
  end)
end

return M
