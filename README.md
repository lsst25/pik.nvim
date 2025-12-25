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

Switch between git worktrees (changes neovim's working directory):

```vim
:PikWorktree            " Open worktree picker
:Telescope pik worktree " Telescope command
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
