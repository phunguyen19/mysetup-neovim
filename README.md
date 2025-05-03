# NeoVim Setup

This repository contains my personal configuration files for NeoVim, organized with a modular structure for easy maintenance and customization.

## Features

### Core

- Plugin management using lazy.nvim for efficient lazy-loading
- Modern UI with catppuccin theme and custom highlights
- Organized configuration structure in lua/rpn/

### Development Tools

- LSP integration with comprehensive setup:
  - Mason for automated language server installation and management
  - Automatic setup for multiple language servers
  - Integrated diagnostics and code actions
- Treesitter for advanced syntax highlighting and code navigation
- Auto-completion with nvim-cmp and multiple sources:
  - LSP suggestions
  - Buffer text
  - Path completion
  - Snippets via LuaSnip
- Formatting and linting integration

### Navigation & Search

- Telescope for powerful fuzzy finding with multiple pickers:
  - File search
  - Live grep (text search)
  - Buffer management
  - Help documentation
- Nvim-tree file explorer with git status integration
- Which-key for discoverable keybindings
- Harpoon for quick file navigation between frequently used files

### UI Enhancements

- Lualine status line with git branch, diagnostics, and mode indicators
- Bufferline for visual buffer management
- Indent guides and rainbow parentheses
- Gitsigns for inline git change indicators
- Colorizer for color code highlighting

### Productivity

- Augment AI code assistant for intelligent coding help
- Comment.nvim for easy code commenting
- Autopairs for automatic bracket completion
- Surround.vim for manipulating text surroundings
- ToggleTerm for integrated terminal experience
- Markdown preview for documentation writing

## Installation

1. Prerequisites:

   - NeoVim 0.9.0 or higher
   - Git
   - Node.js (for LSP servers)
   - A Nerd Font (for icons)
   - ripgrep (for Telescope grep functionality)

2. Clone this repository:

   git clone https://github.com/yourusername/nvim-config.git ~/.config/nvim

3. Launch NeoVim to automatically install plugins:

   nvim

## Key Mappings

### General

- `<Space>` - Leader key
- `jk` - Escape from insert mode
- `<C-s>` - Save file
- `<C-h/j/k/l>` - Navigate between splits

### Augment AI Code Assistant

- `<leader>ac` - Open Augment chat (normal and visual mode)
- `<leader>an` - Start a new Augment chat
- `<leader>at` - Toggle Augment chat window
- `<Ctrl-y>` - Accept Augment code suggestions

### Telescope

- `<leader>ff` - Find files
- `<leader>fg` - Live grep (search in files)
- `<leader>fb` - Browse buffers
- `<leader>fh` - Search help tags
- `<leader>fr` - Recent files

### LSP

- `gd` - Go to definition
- `gr` - Find references
- `K` - Show hover documentation
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol
- `[d` / `]d` - Navigate diagnostics
- `<leader>f` - Format document

### File Navigation

- `<leader>e` - Toggle file explorer
- `<leader>h` - Harpoon mark file
- `<leader>j` - Harpoon quick menu

### Git

- `<leader>gs` - Git status (Fugitive)
- `<leader>gd` - Git diff
- `<leader>gb` - Git blame
- `<leader>gh` - Stage hunk
- `<leader>gu` - Undo hunk

### Terminal

- `<leader>t` - Toggle terminal
- `<Esc>` - Exit terminal mode

## Directory Structure

~/.config/nvim/
├── init.lua # Main entry point
├── lua/
│ └── rpn/ # Personal namespace
│ ├── init.lua # Module loader
│ ├── options.lua # NeoVim options
│ ├── keymaps.lua # Key mappings
│ ├── autocmds.lua # Autocommands
│ └── plugins/ # Plugin configurations
│ ├── init.lua # Plugin loader
│ ├── lsp.lua # LSP configuration
│ ├── telescope.lua # Telescope setup
│ ├── treesitter.lua # Treesitter config
│ ├── cmp.lua # Completion setup
│ ├── augmentcode.lua # Augment AI setup
│ └── ... # Other plugin configs

## Customization

To customize this setup:

1. Edit plugin configurations in `lua/rpn/plugins/`
2. Modify key mappings in `lua/rpn/keymaps.lua`
3. Adjust general settings in `lua/rpn/options.lua`
4. Add new plugins by creating files in the plugins directory

## Troubleshooting

- Run `:checkhealth` to diagnose issues
- Update plugins with `:Lazy update`
- Reinstall language servers with `:Mason`

## License
