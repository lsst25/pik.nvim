local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local pik = require("pik")

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
              -- Reload the buffer to show changes (deferred to avoid LSP issues)
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
      prompt_title = "Pik",
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

return require("telescope").register_extension({
  setup = function(ext_config, config)
    -- Extension setup if needed
  end,
  exports = {
    pik = pick_selector,
  },
})
