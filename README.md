# pik.nvim

Neovim plugin for [pik](https://github.com/lsst25/pik) - switch config options and manage worktrees using Telescope.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "lsst25/pik.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  build = "npm install -g @lsst/pik",
  config = function()
    require("pik").setup()
    require("telescope").load_extension("pik")
  end,
  keys = {
    { "<leader>ps", "<cmd>Telescope pik select<cr>", desc = "Pik select" },
    { "<leader>pw", "<cmd>Telescope pik worktree<cr>", desc = "Pik worktree" },
    { "<leader>pk", "<cmd>PikKillport<cr>", desc = "Pik killport" },
  },
}
```

## Usage

### Select Plugin

Switch between config options defined with `@pik:select` markers:

```vim
:Pik                    " Open selector picker
:PikSelect              " Same as :Pik
:Telescope pik select   " Telescope command
```

### Worktree Plugin

Manage git worktrees directly from neovim:

```vim
:PikWorktree              " Switch between worktrees
:PikWorktreeCreate        " Create a new worktree
:PikWorktreeRemove        " Remove a worktree

:Telescope pik worktree         " Telescope command (switch)
:Telescope pik worktree_create  " Telescope command (create)
:Telescope pik worktree_remove  " Telescope command (remove)
```

**Worktree Switch**: Select a worktree to switch to (changes neovim's cwd).

**Worktree Create**: Create a new worktree from either:
- A new branch (prompts for branch name and directory)
- An existing branch (shows picker with available branches)

**Worktree Remove**: Select a worktree to remove with confirmation. Offers force removal if the worktree has uncommitted changes.

### Killport Plugin

Kill processes running on specific ports:

```vim
:PikKillport              " Prompts for port number and kills process
```

## Configuration

```lua
require("pik").setup({
  cli_path = "pik", -- Path to pik CLI (default: "pik")
})
```

## Requirements

- [pik CLI](https://github.com/lsst25/pik) (`npm install -g @lsst/pik`)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- pik plugins must be configured in your project's `pik.config.ts`

## License

MIT
