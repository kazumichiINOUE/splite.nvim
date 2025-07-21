# literate_mode.nvim

Neovim plugin for Literate Programming with dynamic syntax highlighting modes.

## Features

- Toggle between code-focused and documentation-focused display modes
- Enhanced comment visibility for literate programming
- Simple keymap-based mode switching

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/literate_mode.nvim",
  config = function()
    require("literate_mode").setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/literate_mode.nvim",
  config = function()
    require("literate_mode").setup()
  end
}
```

## Usage

### Default Keymaps

- `<leader>lt` - Toggle literate mode

### Commands

- `:LiterateToggle` - Toggle literate mode

## Configuration

```lua
require("literate_mode").setup({
  -- Configuration options will be added in future versions
})
```

## License

MIT