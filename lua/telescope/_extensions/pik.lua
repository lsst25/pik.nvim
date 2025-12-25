local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local pik = require("pik")

-- Select plugin pickers

local function pick_option(selector, opts)
  opts = themes.get_dropdown({
    layout_config = {
      width = 0.4,
      height = 0.3,
    },
    previewer = false,
  })

  pickers
    .new(opts, {
      prompt_title = selector.name,
      finder = finders.new_table({
        results = selector.options,
        entry_maker = function(option)
          local display = option.name
          if option.isActive then
            display = display .. " (current)"
          end
          return {
            value = option,
            display = display,
            ordinal = option.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local success, result = pik.set_option(selector.name, selection.value.name)
            if success then
              vim.notify(
                string.format("Set %s to %s", selector.name, selection.value.name),
                vim.log.levels.INFO
              )
              vim.schedule(function()
                vim.cmd("checktime")
              end)
            else
              vim.notify("Failed to set option: " .. (result or "unknown error"), vim.log.levels.ERROR)
            end
          end
        end)
        return true
      end,
    })
    :find()
end

local function pick_selector(opts)
  local selectors, err = pik.list_selectors()
  if err then
    vim.notify("pik: " .. err, vim.log.levels.ERROR)
    return
  end

  if not selectors or #selectors == 0 then
    vim.notify("No selectors found", vim.log.levels.WARN)
    return
  end

  opts = themes.get_dropdown({
    layout_config = {
      width = 0.5,
      height = 0.4,
    },
    previewer = false,
  })

  pickers
    .new(opts, {
      prompt_title = "Pik Select",
      finder = finders.new_table({
        results = selectors,
        entry_maker = function(selector)
          local current = selector.activeOption or "none"
          local display = string.format("%s (%s) - %s", selector.name, current, selector.file)
          return {
            value = selector,
            display = display,
            ordinal = selector.name .. " " .. selector.file,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            pick_option(selection.value, opts)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Worktree plugin pickers

local function pick_worktree(opts)
  local worktrees, err = pik.list_worktrees()
  if err then
    vim.notify("pik: " .. err, vim.log.levels.ERROR)
    return
  end

  if not worktrees or #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  opts = themes.get_dropdown({
    layout_config = {
      width = 0.6,
      height = 0.4,
    },
    previewer = false,
  })

  local cwd = vim.fn.getcwd()

  pickers
    .new(opts, {
      prompt_title = "Pik Worktree (switch)",
      finder = finders.new_table({
        results = worktrees,
        entry_maker = function(worktree)
          local branch = worktree.branch or "(detached)"
          local is_current = worktree.path == cwd
          local main_label = worktree.isMain and " [main]" or ""
          local current_label = is_current and " (current)" or ""

          local display = string.format("%s%s%s - %s", branch, main_label, current_label, worktree.path)
          return {
            value = worktree,
            display = display,
            ordinal = branch .. " " .. worktree.path,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local success, result = pik.switch_worktree(selection.value.path)
            if success then
              vim.notify(
                string.format("Switched to worktree: %s", selection.value.branch or selection.value.path),
                vim.log.levels.INFO
              )
            else
              vim.notify("Failed to switch worktree: " .. (result or "unknown error"), vim.log.levels.ERROR)
            end
          end
        end)
        return true
      end,
    })
    :find()
end

local function worktree_create(opts)
  -- First, ask whether to create new branch or use existing
  vim.ui.select({ "Create new branch", "Use existing branch" }, {
    prompt = "Worktree from:",
  }, function(choice)
    if not choice then
      return
    end

    local is_new_branch = choice == "Create new branch"

    if is_new_branch then
      -- Ask for new branch name
      vim.ui.input({ prompt = "New branch name: " }, function(branch_name)
        if not branch_name or branch_name == "" then
          return
        end

        -- Ask for worktree directory name
        local default_name = branch_name:gsub("/", "-")
        vim.ui.input({ prompt = "Worktree directory name: ", default = default_name }, function(wt_name)
          if not wt_name or wt_name == "" then
            wt_name = default_name
          end

          local success, result = pik.create_worktree(branch_name, true, wt_name)
          if success then
            vim.notify("Created worktree for branch: " .. branch_name, vim.log.levels.INFO)
          else
            vim.notify("Failed to create worktree: " .. (result or "unknown error"), vim.log.levels.ERROR)
          end
        end)
      end)
    else
      -- Pick from existing branches
      local branches, err = pik.list_branches()
      if err then
        vim.notify("Failed to list branches: " .. err, vim.log.levels.ERROR)
        return
      end

      -- Filter out branches that already have worktrees
      local worktrees = pik.list_worktrees() or {}
      local worktree_branches = {}
      for _, wt in ipairs(worktrees) do
        if wt.branch then
          worktree_branches[wt.branch] = true
        end
      end

      local available_branches = {}
      for _, branch in ipairs(branches) do
        if not worktree_branches[branch] then
          table.insert(available_branches, branch)
        end
      end

      if #available_branches == 0 then
        vim.notify("All branches already have worktrees", vim.log.levels.WARN)
        return
      end

      opts = themes.get_dropdown({
        layout_config = {
          width = 0.5,
          height = 0.4,
        },
        previewer = false,
      })

      pickers
        .new(opts, {
          prompt_title = "Select branch for worktree",
          finder = finders.new_table({
            results = available_branches,
            entry_maker = function(branch)
              return {
                value = branch,
                display = branch,
                ordinal = branch,
              }
            end,
          }),
          sorter = conf.generic_sorter(opts),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                local branch_name = selection.value
                local default_name = branch_name:gsub("/", "-")

                vim.ui.input({ prompt = "Worktree directory name: ", default = default_name }, function(wt_name)
                  if not wt_name or wt_name == "" then
                    wt_name = default_name
                  end

                  local success, result = pik.create_worktree(branch_name, false, wt_name)
                  if success then
                    vim.notify("Created worktree for branch: " .. branch_name, vim.log.levels.INFO)
                  else
                    vim.notify("Failed to create worktree: " .. (result or "unknown error"), vim.log.levels.ERROR)
                  end
                end)
              end
            end)
            return true
          end,
        })
        :find()
    end
  end)
end

-- Killport plugin picker

local function pick_killport(opts)
  local ports, err = pik.list_ports()
  if err then
    vim.notify("pik: " .. err, vim.log.levels.ERROR)
    return
  end

  if not ports or #ports == 0 then
    vim.notify("No listening ports found", vim.log.levels.WARN)
    return
  end

  opts = themes.get_dropdown({
    layout_config = {
      width = 0.5,
      height = 0.4,
    },
    previewer = false,
  })

  pickers
    .new(opts, {
      prompt_title = "Kill Port",
      finder = finders.new_table({
        results = ports,
        entry_maker = function(port_info)
          local display = string.format(":%d - %s (pid %d)", port_info.port, port_info.command, port_info.pid)
          return {
            value = port_info,
            display = display,
            ordinal = tostring(port_info.port) .. " " .. port_info.command,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local port_info = selection.value
            vim.ui.select({ "Yes", "No" }, {
              prompt = string.format("Kill process on port %d (%s)?", port_info.port, port_info.command),
            }, function(confirm)
              if confirm == "Yes" then
                local success, result = pik.kill_port(port_info.port)
                if success then
                  vim.notify(result, vim.log.levels.INFO)
                else
                  vim.notify(result, vim.log.levels.ERROR)
                end
              end
            end)
          end
        end)
        return true
      end,
    })
    :find()
end

local function worktree_remove(opts)
  local worktrees, err = pik.list_worktrees()
  if err then
    vim.notify("pik: " .. err, vim.log.levels.ERROR)
    return
  end

  -- Filter out main worktree
  local removable = {}
  for _, wt in ipairs(worktrees or {}) do
    if not wt.isMain then
      table.insert(removable, wt)
    end
  end

  if #removable == 0 then
    vim.notify("No removable worktrees found", vim.log.levels.WARN)
    return
  end

  opts = themes.get_dropdown({
    layout_config = {
      width = 0.6,
      height = 0.4,
    },
    previewer = false,
  })

  pickers
    .new(opts, {
      prompt_title = "Remove worktree",
      finder = finders.new_table({
        results = removable,
        entry_maker = function(worktree)
          local branch = worktree.branch or "(detached)"
          local display = string.format("%s - %s", branch, worktree.path)
          return {
            value = worktree,
            display = display,
            ordinal = branch .. " " .. worktree.path,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local wt = selection.value
            vim.ui.select({ "Yes", "No" }, {
              prompt = string.format("Remove worktree %s?", wt.branch or wt.path),
            }, function(confirm)
              if confirm == "Yes" then
                local success, result = pik.remove_worktree(wt.path, false)
                if success then
                  vim.notify("Removed worktree: " .. (wt.branch or wt.path), vim.log.levels.INFO)
                else
                  -- Try with force
                  vim.ui.select({ "Yes, force remove", "No" }, {
                    prompt = "Worktree may have changes. Force remove?",
                  }, function(force_confirm)
                    if force_confirm == "Yes, force remove" then
                      local force_success, force_result = pik.remove_worktree(wt.path, true)
                      if force_success then
                        vim.notify("Removed worktree: " .. (wt.branch or wt.path), vim.log.levels.INFO)
                      else
                        vim.notify(
                          "Failed to remove worktree: " .. (force_result or "unknown error"),
                          vim.log.levels.ERROR
                        )
                      end
                    end
                  end)
                end
              end
            end)
          end
        end)
        return true
      end,
    })
    :find()
end

return require("telescope").register_extension({
  setup = function(ext_config, config)
    -- Extension setup if needed
  end,
  exports = {
    pik = pick_selector, -- Default/legacy
    select = pick_selector,
    worktree = pick_worktree,
    worktree_create = worktree_create,
    worktree_remove = worktree_remove,
    killport = pick_killport,
  },
})
