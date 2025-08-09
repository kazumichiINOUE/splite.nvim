# SPLITE

*SPLITE spreads your coding perspectives in Literate Programming*

Neovim plugin for enhanced literate programming with spread view code display 
and dynamic syntax highlighting modes.

## Features

- **Spread View**: Multi-pane spread display for continuous code reading
- **Literate Mode**: Toggle between code-focused and documentation-focused views
- **Todo Mode**: Dedicated TODO management for Markdown files with 3-pane view
- **Enhanced Comments**: Markdown-style formatting within code comments
- **Multi-language Support**: Dynamic syntax highlighting for multiple languages
- **Seamless Integration**: Simple keymap-based mode switching

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "kazumichiINOUE/splite.nvim",
  config = function()
    require("splite").setup()
  end
}
```

<!--
### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "kazumichiINOUE/splite.nvim",
  config = function()
    require("splite").setup()
  end
}
```
-->

## Usage

### Default Keymaps

- `<leader>lt` - Toggle literate mode
- `<leader>lv` - Toggle spread view
- `<leader>ld` - Toggle todo mode (Markdown files only)

### Commands

- `:SpliteToggle` - Toggle literate mode
- `:SpliteSpread` - Toggle spread view mode
- `:SpliteTodo` - Toggle todo mode (Markdown files only)

## Todo Mode

Todo Mode provides a specialized interface for managing TODO items in Markdown files.

### Features

- **3-Pane Layout**: Left pane shows TODO list, center and right panes show continuous Markdown content
- **Auto-detection**: Automatically extracts `- [ ]` and `- [x]` formatted TODO items
- **Right-aligned Display**: TODOs displayed as "Task Name [x]" format, right-aligned
- **Real-time Updates**: TODO list updates automatically as you edit the file
- **Visual Distinction**: Completed TODOs (`[x]`) shown in dimmed color
- **Read-only Panel**: Left TODO panel prevents accidental editing

### Usage

1. Open any Markdown file containing TODO items in the format `- [ ]` or `- [x]`
2. Press `<leader>ld` or run `:SpliteTodo` to enter Todo Mode
3. Edit TODOs in the center or right pane - the left panel updates automatically
4. Press `<leader>ld` again to exit Todo Mode

## Supported Languages in Literate Mode

| Language | Status | Features |
|----------|--------|----------|
| Rust     | ✅     | Full Markdown support, Headers, Bold/Italic, Code blocks, Lists |
| Python   | ✅     | Full Markdown support, Headers, Bold/Italic, Code blocks, Lists |
| Lua      | ✅     | Full Markdown support, Headers, Bold/Italic, Code blocks, Lists |
| Markdown | ✅     | Todo Mode with specialized TODO management |
| C/C++    | 🚧     | Planned |

## Configuration

```lua
require("splite").setup({
  -- Configuration options will be added in future versions
})
```

## License

MIT
