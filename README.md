# pik.nvim

Neovim plugin for [pik](https://github.com/lsst25/pik) - switch config options using Telescope.

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
    { "<leader>ps", "<cmd>Telescope pik<cr>", desc = "Pik switch" },
  },
}
```

## Usage

Press `<leader>ps` to open the Telescope picker and switch between pik options.

## Configuration

```lua
require("pik").setup({
  cli_path = "pik", -- Path to pik CLI (default: "pik")
})
```

## License

MIT
