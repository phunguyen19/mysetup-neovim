# Neovim Keymaps Reference

**Leader Key:** `<Space>`

## General

| Mode | Keymap | Description |
|------|--------|-------------|
| `i` | `jk` | Exit insert mode |
| `n` | `<leader>nh` | Clear search highlights |
| `n` | `<leader>+` | Increment number under cursor |
| `n` | `<leader>-` | Decrement number under cursor |

## Window Management

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>sv` | Split window vertically |
| `n` | `<leader>sh` | Split window horizontally |
| `n` | `<leader>se` | Make splits equal size |
| `n` | `<leader>sx` | Close current split |
| `n` | `<leader>sm` | Maximize/minimize a split (vim-maximizer) |
| `n` | `<C-h>` | Navigate to left split (vim-tmux-navigator) |
| `n` | `<C-j>` | Navigate to bottom split (vim-tmux-navigator) |
| `n` | `<C-k>` | Navigate to top split (vim-tmux-navigator) |
| `n` | `<C-l>` | Navigate to right split (vim-tmux-navigator) |

## Tab Management

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>to` | Open new tab |
| `n` | `<leader>tx` | Close current tab |
| `n` | `<leader>tn` | Go to next tab |
| `n` | `<leader>tp` | Go to previous tab |
| `n` | `<leader>tf` | Open current buffer in new tab |
| `n` | `<leader>t[1-9]` | Go to tab position (press number after `<leader>t`) |
| `n` | `<leader>tm` | Move current tab to position (prompts for number) |

## Path & Directory Operations

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>pr` | Copy relative path of current file |
| `n` | `<leader>pa` | Copy absolute path of current file |
| `n` | `<leader>pdr` | Copy relative directory of current file |
| `n` | `<leader>pda` | Copy absolute directory of current file |
| `n` | `<leader>po` | Copy current working directory (`:pwd`) |

## File Explorer (nvim-tree)

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>ee` | Toggle file explorer |
| `n` | `<leader>ef` | Toggle file explorer on current file |
| `n` | `<leader>ec` | Collapse file explorer |
| `n` | `<leader>er` | Refresh file explorer |

## Telescope (Fuzzy Finding)

### Files

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>ff` | Fuzzy find files in cwd |
| `n` | `<leader>fu` | Fuzzy find including hidden and ignored files |
| `n` | `<leader>fr` | Fuzzy find recent files |
| `n` | `<leader>fb` | Browse buffers |
| `n` | `<leader>fc` | Fuzzy search in current buffer |

### Search

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>fgg` | Live grep (search string in cwd) |
| `n` | `<leader>fga` | Live grep with args |
| `n` | `<leader>fk` | Find keymaps |
| `n` | `<leader>fj` | Find in jumplist |
| `n` | `<leader>ft` | Find todos |

### Git

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>fgs` | Telescope git status |
| `n` | `<leader>fgb` | Telescope git buffer commits |

### Quickfix

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>fqq` | Find in quickfix list |
| `n` | `<leader>fqh` | Find in quickfix history |

## LSP (Language Server Protocol)

| Mode | Keymap | Description | Location |
|------|--------|-------------|----------|
| `n` | `gR` | Show LSP references | lua/rpn/plugins/lsp/lspconfig.lua:24 |
| `n` | `gD` | Go to declaration | lua/rpn/plugins/lsp/lspconfig.lua:27 |
| `n` | `gd` | Show LSP definitions | lua/rpn/plugins/lsp/lspconfig.lua:30 |
| `n` | `gi` | Show LSP implementations | lua/rpn/plugins/lsp/lspconfig.lua:33 |
| `n` | `gt` | Show LSP type definitions | lua/rpn/plugins/lsp/lspconfig.lua:36 |
| `n`, `v` | `<leader>ca` | See available code actions | lua/rpn/plugins/lsp/lspconfig.lua:39 |
| `n` | `<leader>rn` | Smart rename | lua/rpn/plugins/lsp/lspconfig.lua:42 |
| `n` | `<leader>lD` | Show buffer diagnostics | lua/rpn/plugins/lsp/lspconfig.lua:45 |
| `n` | `<leader>ld` | Show line diagnostics | lua/rpn/plugins/lsp/lspconfig.lua:48 |
| `n` | `[d` | Go to previous diagnostic | lua/rpn/plugins/lsp/lspconfig.lua:51 |
| `n` | `]d` | Go to next diagnostic | lua/rpn/plugins/lsp/lspconfig.lua:54 |
| `n` | `K` | Show documentation for what is under cursor | lua/rpn/plugins/lsp/lspconfig.lua:57 |
| `n` | `<leader>rs` | Restart LSP | lua/rpn/plugins/lsp/lspconfig.lua:60 |

## Git Operations

### Gitsigns (Hunks)

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `]h` | Next hunk |
| `n` | `[h` | Previous hunk |
| `n` | `<leader>hs` | Stage hunk |
| `v` | `<leader>hs` | Stage hunk (visual selection) |
| `n` | `<leader>hr` | Reset hunk |
| `v` | `<leader>hr` | Reset hunk (visual selection) |
| `n` | `<leader>hS` | Stage entire buffer |
| `n` | `<leader>hR` | Reset entire buffer |
| `n` | `<leader>hu` | Undo stage hunk |
| `n` | `<leader>hp` | Preview hunk |
| `n` | `<leader>hb` | Blame line (full) |
| `n` | `<leader>hB` | Toggle current line blame |
| `n` | `<leader>hd` | Diff this |
| `n` | `<leader>hD` | Diff this ~ |
| `o`, `x` | `ih` | Select hunk (text object) |

### LazyGit

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>gl` | Open LazyGit |

### Diffview

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>gdo` | Diffview: Open |
| `n` | `<leader>gdc` | Diffview: Close |
| `n` | `<leader>gdf` | Diffview: File History (current file) |
| `n` | `<leader>gdF` | Diffview: Project History |

## Terminal (ToggleTerm)

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<C-\>` | Toggle last terminal |
| `n` | `<leader>tt` | Open terminal (float) |

## Diagnostics & Trouble

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>xx` | Diagnostics (Trouble) |
| `n` | `<leader>xX` | Buffer Diagnostics (Trouble) |
| `n` | `<leader>cs` | Symbols (Trouble) |
| `n` | `<leader>cl` | LSP Definitions/References (Trouble) |
| `n` | `<leader>xL` | Location List (Trouble) |
| `n` | `<leader>xQ` | Quickfix List (Trouble) |

## Completion (nvim-cmp)

_Active in Insert mode when completion menu is open_

| Mode | Keymap | Description |
|------|--------|-------------|
| `i` | `<C-k>` | Previous suggestion |
| `i` | `<C-j>` | Next suggestion |
| `i` | `<C-b>` | Scroll docs up |
| `i` | `<C-f>` | Scroll docs down |
| `i` | `<C-Space>` | Show completion suggestions |
| `i` | `<C-e>` | Close completion window |
| `i` | `<CR>` | Confirm selection |

## AI Assistants

### GitHub Copilot
_Enabled when `NVIM_AI_ASSISTANT_CHAT=github_copilot`_

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>ac` | Copilot chat |
| `n` | `<leader>at` | Copilot toggle chat |

### Augment
_Enabled when `NVIM_AI_ASSISTANT_CHAT=augment`_

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>ac` | Augment chat |
| `v` | `<leader>ac` | Augment chat with selection |
| `n` | `<leader>an` | Augment new chat |
| `n` | `<leader>at` | Augment toggle chat |
| `i` | `<C-y>` | Accept Augment suggestion |
| `v` | `<leader>aa` | Apply code block to file (augment_apply) |

### Claude Code
_Enabled when `NVIM_AI_ASSISTANT_CHAT=claude`_

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>ac` | Toggle Claude |
| `n` | `<leader>af` | Focus Claude |
| `n` | `<leader>ar` | Resume Claude |
| `n` | `<leader>aC` | Continue Claude |
| `n` | `<leader>am` | Select Claude model |
| `n` | `<leader>ab` | Add current buffer |
| `v` | `<leader>as` | Send to Claude |
| `n` | `<leader>as` | Add file (in file explorer) |
| `n` | `<leader>aa` | Accept diff |
| `n` | `<leader>ad` | Deny diff |

## Debugging (nvim-dap)

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>da` | Run with Args |
| `n` | `<leader>db` | Toggle Breakpoint |
| `n` | `<leader>dB` | Breakpoint Condition |
| `n` | `<leader>dc` | Run/Continue |
| `n` | `<leader>dC` | Run to Cursor |
| `n` | `<leader>dg` | Go to Line (No Execute) |
| `n` | `<leader>di` | Step Into |
| `n` | `<leader>dI` | Step Out |
| `n` | `<leader>dj` | Down |
| `n` | `<leader>dk` | Up |
| `n` | `<leader>dl` | Run Last |
| `n` | `<leader>do` | Step Over |
| `n` | `<leader>dp` | Pause |
| `n` | `<leader>dr` | Toggle REPL |
| `n` | `<leader>ds` | Session |
| `n` | `<leader>dx` | Terminate Session |
| `n` | `<leader>dw` | Widgets (Show values) |
| `n`, `v` | `<leader>du` | Toggle Dap UI |
| `n`, `v` | `<leader>de` | Eval expression |

## Code Editing

### Comment.nvim
_Uses default keymaps from Comment.nvim_

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `gcc` | Toggle line comment |
| `n` | `gbc` | Toggle block comment |
| `v` | `gc` | Toggle comment (selection) |
| `v` | `gb` | Toggle block comment (selection) |

### Substitute

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `s` | Substitute with motion |
| `n` | `ss` | Substitute line |
| `n` | `S` | Substitute to end of line |
| `x` | `s` | Substitute in visual mode |

### Surround (nvim-surround)
_Uses default keymaps from nvim-surround_

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `ys{motion}{char}` | Add surrounding |
| `n` | `yss{char}` | Add surrounding to line |
| `n` | `ds{char}` | Delete surrounding |
| `n` | `cs{old}{new}` | Change surrounding |
| `v` | `S{char}` | Add surrounding (visual) |

## Session Management

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>wr` | Restore session for cwd |
| `n` | `<leader>ws` | Save session |

## Todo Comments

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `]t` | Next todo comment |
| `n` | `[t` | Previous todo comment |

## Code Outline

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `<leader>oo` | Toggle outline |

## Formatting & Linting

| Mode | Keymap | Description |
|------|--------|-------------|
| `n`, `v` | `<leader>mp` | Format file or range |
| `n` | `<leader>ll` | Trigger linting for current file |

### Commands

| Command | Description |
|---------|-------------|
| `:Format` | Format current file/selection |
| `:FormatDisable` | Disable format-on-save globally |
| `:FormatDisable!` | Disable format-on-save for current buffer |
| `:FormatEnable` | Re-enable format-on-save |
| `:ESLintDebug` | Debug ESLint configuration |

## Built-in Neovim Keymaps

### Essential Movement

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `h/j/k/l` | Left/Down/Up/Right |
| `n` | `w` | Next word |
| `n` | `b` | Previous word |
| `n` | `e` | End of word |
| `n` | `0` | Start of line |
| `n` | `^` | First non-blank character |
| `n` | `$` | End of line |
| `n` | `gg` | First line |
| `n` | `G` | Last line |
| `n` | `{number}G` | Go to line number |
| `n` | `%` | Jump to matching bracket |
| `n` | `<C-u>` | Scroll up half page |
| `n` | `<C-d>` | Scroll down half page |
| `n` | `<C-o>` | Jump to previous location |
| `n` | `<C-i>` | Jump to next location |

### Editing

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `i` | Insert before cursor |
| `n` | `a` | Insert after cursor |
| `n` | `I` | Insert at start of line |
| `n` | `A` | Insert at end of line |
| `n` | `o` | New line below |
| `n` | `O` | New line above |
| `n` | `u` | Undo |
| `n` | `<C-r>` | Redo |
| `n` | `dd` | Delete line |
| `n` | `yy` | Yank (copy) line |
| `n` | `p` | Paste after cursor |
| `n` | `P` | Paste before cursor |
| `v` | `y` | Yank selection |
| `v` | `d` | Delete selection |
| `v` | `c` | Change selection |
| `n` | `.` | Repeat last change |

### Visual Mode

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `v` | Enter visual mode |
| `n` | `V` | Enter visual line mode |
| `n` | `<C-v>` | Enter visual block mode |
| `v` | `>` | Indent selection |
| `v` | `<` | Unindent selection |

### Search & Replace

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `/` | Search forward |
| `n` | `?` | Search backward |
| `n` | `n` | Next search result |
| `n` | `N` | Previous search result |
| `n` | `*` | Search word under cursor (forward) |
| `n` | `#` | Search word under cursor (backward) |
| `n` | `:%s/old/new/g` | Replace all in file |
| `v` | `:s/old/new/g` | Replace in selection |

### Marks

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `m{a-z}` | Set local mark |
| `n` | `m{A-Z}` | Set global mark |
| `n` | `'{mark}` | Jump to mark line |
| `n` | `` `{mark} `` | Jump to mark position |

### Registers

| Mode | Keymap | Description |
|------|--------|-------------|
| `n` | `"{register}` | Use specific register |
| `n` | `"+y` | Yank to system clipboard |
| `n` | `"+p` | Paste from system clipboard |

## Quick Reference by Prefix

| Prefix | Category |
|--------|----------|
| `<leader>a` | AI Assistants |
| `<leader>c` | Code Actions / LSP |
| `<leader>d` | Debugging |
| `<leader>e` | File Explorer |
| `<leader>f` | Fuzzy Finding (Telescope) |
| `<leader>g` | Git Operations |
| `<leader>h` | Git Hunks |
| `<leader>l` | LSP/Linting |
| `<leader>m` | Formatting |
| `<leader>n` | Miscellaneous |
| `<leader>o` | Outline |
| `<leader>p` | Path/Project |
| `<leader>r` | Rename/Restart |
| `<leader>s` | Splits/Window |
| `<leader>t` | Tabs/Terminal/Todos |
| `<leader>w` | Session (Workspace) |
| `<leader>x` | Diagnostics/Trouble |
| `g*` | Go to / LSP navigation |
| `]` / `[` | Next/Previous navigation |
