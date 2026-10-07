# Things 3 for Neovim

View and manage [Things 3](https://culturedcode.com/things/) to-dos from Neovim: browse lists, complete, schedule, tag, move and edit to-dos, and capture TODO comments from code with a link back to the source line.

**The Things database is never opened.** Writes go through the official [`things:///` URL scheme](https://culturedcode.com/things/support/articles/2803573/); reads go through Things' AppleScript dictionary (JXA via `osascript`).

## Requirements

- macOS with Things 3
- Neovim 0.10+
- telescope.nvim (for `<leader>Tf` search); dressing.nvim recommended for nicer prompts
- Things URLs enabled, with an auth token (needed for anything that changes an existing to-do)

## Setup

1. In Things: **Settings → General → Enable Things URLs**, then **Manage** and copy the auth token.
2. Store it in the macOS Keychain:

   ```sh
   security add-generic-password -s things3-nvim -a "$USER" -w '<token>'
   ```

   Or export `THINGS_AUTH_TOKEN` instead. Run `:ThingsTokenCheck` to confirm; it never prints the token.

3. The first read triggers a macOS prompt asking whether your terminal may control Things 3 — allow it (System Settings → Privacy & Security → Automation if you missed it).

Adding to-dos works without a token; completing, scheduling, tagging, moving and editing need it.

## Keymaps

### Global (`<leader>T`)

| Keys | Action |
|---|---|
| `<leader>Tt` | Today |
| `<leader>Ti` | Inbox |
| `<leader>Tu` | Upcoming |
| `<leader>Tn` | Anytime |
| `<leader>Ts` | Someday |
| `<leader>Tl` | Logbook (last 50) |
| `<leader>Tp` | Pick a project and open it |
| `<leader>Tr` | Pick an area and open it |
| `<leader>T#` | Pick a tag and open it |
| `<leader>Tf` | Fuzzy search all open to-dos (Telescope) |
| `<leader>Ta` | Quick add to Inbox |
| `<leader>Tc` | Capture current line (normal) or selection (visual) as a to-do |
| `<leader>TP` | Add a project |
| `<leader>To` | Show the current list in the Things app |

### In a list buffer

| Keys | Action |
|---|---|
| `x` | Toggle complete |
| `X` | Cancel |
| `u` | Undo the last complete/cancel |
| `s` | Schedule: today, evening, tomorrow, anytime, someday, or a date (`2026-10-20`, `next friday`) |
| `d` | Deadline (empty clears it) |
| `t` | Tags, comma separated, with completion |
| `m` | Move to a project or area |
| `a` / `A` | Add a to-do to this list — quick prompt / full editor |
| `<CR>` | Edit in a float |
| `K` | Peek notes |
| `o` | Reveal the to-do in Things |
| `R` | Refresh |
| `gi` `gt` `gu` `gn` `gs` `gl` | Inbox / Today / Upcoming / Anytime / Someday / Logbook |
| `q` | Close |
| `g?` | Help |

`x`, `X`, `s`, `d`, `t` and `m` also work in visual mode on every selected to-do, sent to Things as one batch.

To-dos added with `a` inherit the list: Today → `when=today`, a project → that project, a tag → that tag, and so on.

### In the Telescope search

| Keys | Action |
|---|---|
| `<CR>` | Edit in a float |
| `<C-x>` | Complete |
| `<C-o>` | Reveal in Things |

## The editor

`<CR>` (or `A`) opens the to-do as text. `:w` saves and sends only the fields you changed; `q` discards.

```
Review settlement PR
when: 2026-10-07
deadline:
tags: work, payments
- [ ] run integration tests
---
Notes in markdown…
```

- Line 1 is the title; `---` separates the header from the notes.
- Clearing `when:` moves the to-do to Anytime; clearing `deadline:` removes it.
- `- [ ] item` lines are **appended** to the checklist. Existing checklist items aren't shown because AppleScript can't read them.

## Capturing from code

`<leader>Tc` (or `:ThingsCapture` over a range) turns the line or selection into an Inbox to-do:

- Comment leaders and markers are stripped: `// TODO(rpn): retry on 429` becomes `retry on 429`.
- The first non-empty line is the title (editable before it's sent); the rest becomes notes.
- The notes end with a link back to the source, e.g. `[nvim/lua/rpn/things/url.lua:10-13](file:///…)`.

## Commands

| Command | Action |
|---|---|
| `:Things [today\|inbox\|upcoming\|anytime\|someday\|logbook]` | Open a list (default: today) |
| `:ThingsAdd [title]` | Add to Inbox (prompts if no title) |
| `:[range]ThingsCapture` | Capture lines as a to-do |
| `:ThingsSearch` | Fuzzy search open to-dos |
| `:ThingsProject` / `:ThingsArea` / `:ThingsTag` | Pick and open |
| `:ThingsTokenCheck` | Check the auth token is configured |

## Configuration

`require("rpn.things").setup()` is called from `lua/rpn/core/init.lua`. Defaults:

```lua
require("rpn.things").setup({
  keymap_prefix = "<leader>T", -- "" disables the global keymaps
  refresh_delay_ms = 400, -- wait before re-reading after a write
  logbook_limit = 50,
  token = { keychain_service = "things3-nvim", env = "THINGS_AUTH_TOKEN" },
  capture = { strip_comment_markers = true, backlink = true },
})
```

`setup()` only registers commands and keymaps; everything else loads on first use.

## Limitations

These come from Things' URL scheme and AppleScript dictionary:

- **No delete.** The URL scheme can't delete or trash; cancel with `X` and empty it in Things.
- **No reordering.** Lists show Things' own order; reorder in the app.
- **Checklists are write-only** (see [The editor](#the-editor)).
- **Writes are fire-and-forget.** Things doesn't report success, so lists update optimistically (`(syncing)`) and re-read shortly after. A wrong or revoked token is silently ignored by Things — the re-read shows the to-do unchanged. Run `:ThingsTokenCheck`, or regenerate the token in Things.
- **Large lists are slow to read.** AppleScript takes ~1–3s for lists with hundreds of items (Anytime, Logbook). Reads are async, so Neovim stays responsive.

## Security

- The token is read from the Keychain (or env), cached in memory, and never logged — error messages are redacted.
- URLs are handed to `jxa/open.js` on **stdin**, so the token never appears in process arguments (`ps`).
- No shell is involved: every process is spawned with an argv list, and data reaches JXA as arguments, never as script source.
- All URL parameters are validated against a per-command allow-list and percent-encoded, so values can't inject extra parameters.

## Layout

| File | Responsibility |
|---|---|
| `init.lua` | `setup()`, commands, global keymaps |
| `client.lua` | Public API: async reads and writes, token injection, error redaction |
| `url.lua` | Builds and validates `things:///` URLs |
| `jxa/read.js` | Read-only AppleScript queries, JSON out |
| `jxa/open.js` | Opens a URL from stdin without focusing Things |
| `token.lua` | Keychain / env token lookup |
| `model.lua` | To-do shape, dates, status transitions |
| `view.lua` | List buffers and their keymaps |
| `editor.lua` | Float editor |
| `capture.lua` | Capture from code |
| `pickers.lua` | Project/area/tag pickers, Telescope search |

## Tests

```sh
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/things { minimal_init = 'tests/minimal_init.lua', sequential = true }"
```

The specs (`tests/things/`) stub process spawning and never touch Things.
