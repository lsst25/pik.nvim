if vim.g.loaded_pik then
  return
end
vim.g.loaded_pik = true

vim.api.nvim_create_user_command("Pik", function()
  require("pik").switch()
end, { desc = "Open pik selector picker" })

vim.api.nvim_create_user_command("PikSelect", function()
  require("pik").switch()
end, { desc = "Open pik selector picker" })

vim.api.nvim_create_user_command("PikWorktree", function()
  require("pik").worktree()
end, { desc = "Open pik worktree picker" })
