# Augment Apply

A Neovim plugin that allows you to apply code blocks directly to files from your buffer.

## Features

- Parse code blocks with metadata headers
- Apply code to files with different modes (EDIT, APPEND, PREPEND, EXCERPT)
- Works with visual selection

## Installation

Using your preferred plugin manager:

```lua
-- Packer
use 'username/augment_apply'

-- Lazy.nvim
{
  'username/augment_apply',
  config = function()
    require('augment_apply').setup()
  end
}
```

## Usage

1. Select a code block with metadata in visual mode
2. Press `<leader>aa` to apply the code to the specified file

The code block must have metadata in the first line with the following format:

```
path=/path/to/file mode=MODE
```

Where MODE can be:

- `EDIT`: Replace the entire file content
- `APPEND`: Add content to the end of the file
- `PREPEND`: Add content to the beginning of the file
- `EXCERPT`: Replace a specific section of the file (not fully implemented)

## Example

Select this block in visual mode and press `<leader>aa`:

```
path=/tmp/test.txt mode=EDIT
This is a test file
with some content
```

This will create or replace `/tmp/test.txt` with the specified content.

## Configuration

```lua
require('augment_apply').setup({
  -- Default options (shown with their default values)
  keymaps = {
    apply = '<leader>aa',
  }
})
```

## Commands

The plugin registers the following commands:

- `:AugmentApply` - Apply the currently selected code block to the specified file

## How It Works

The plugin:

1. Gets the selected text in visual mode
2. Parses the first line for metadata (path and mode)
3. Extracts the actual content to apply
4. Creates directories if they don't exist
5. Applies the content to the file according to the specified mode

## License

MIT
