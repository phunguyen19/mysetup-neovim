# Augment Apply

A simple Neovim plugin that allows you to apply code blocks directly to files from your buffer.

## Installation

Using your preferred plugin manager:

```lua
-- Packer
use 'your-username/augment_apply'

-- Lazy.nvim
{
  'your-username/augment_apply',
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
require('augment_apply').setup()
```

The setup function accepts no parameters but registers the `<leader>aa` keybinding.
