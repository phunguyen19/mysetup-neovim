# Obsidian keymaps

`epwalsh/obsidian.nvim` (config: `lua/rpn/plugins/obsidian.lua`). Prefix `<leader>O` (capital O —
`<leader>o` is orgmode, `<leader>n` is org-roam).

Vaults: `Programming` (`~/obsidian/Programming`), `HexTrust` (`~/obsidian/HexTrust`). The plugin
loads when you open a `.md` file inside a vault, or on any `<leader>O` keymap.

---

## Global (any buffer)

| Key | Action |
| --- | --- |
| `<leader>Of` | Find note (quick switch, Telescope) |
| `<leader>Os` | Grep the vault |
| `<leader>On` | New note |
| `<leader>Or` | Rename note (updates backlinks) |
| `<leader>Ot` | Today's daily note |
| `<leader>Oy` | Yesterday's daily note |
| `<leader>Ob` | Backlinks to current note |
| `<leader>Ol` | Links in current note |
| `<leader>Og` | Tags |
| `<leader>Ow` | Switch vault (workspace) |
| `<leader>Oo` | Open current note in the Obsidian app |
| `<leader>Op` | Paste image from clipboard (saved to `_attachments`) |

## Visual mode

| Key | Action |
| --- | --- |
| `<leader>Ol` | Link selection to an existing note |
| `<leader>On` | Link selection to a new note |
| `<leader>Oe` | Extract selection into a new note |

## Vault markdown buffers (buffer-local)

| Key | Action |
| --- | --- |
| `<CR>` | Smart action: follow `[[link]]` under cursor, or toggle checkbox |
| `gf` | Follow link under cursor (falls back to normal `gf`) |
| `<leader>ch` | Toggle checkbox |

## Insert mode (nvim-cmp)

| Trigger | Completes |
| --- | --- |
| `[[` | Note links |
| `#` | Tags |

Completion starts after 2 characters.

---

## Commands without a keymap

| Command | Action |
| --- | --- |
| `:ObsidianTomorrow` | Tomorrow's daily note |
| `:ObsidianToday <n>` | Daily note `n` days from today (negative = past) |
| `:ObsidianDailies` | Pick from recent daily notes |
| `:ObsidianTags <tag>...` | Notes with the given tags |
| `:ObsidianFollowLink [vsplit\|hsplit]` | Follow link in a split |
| `:ObsidianToggleCheckbox` | Toggle checkbox |
| `:ObsidianTOC` | Table of contents for current note |
