-- Native treesitter incremental selection for Neovim 0.12+.
--
-- tree-sitter-manager provides highlighting only, so this rebuilds the classic
-- node-incremental / node-decremental behaviour directly on the core
-- `vim.treesitter` API (NOT through tree-sitter-manager or nvim-treesitter).
--
-- Keys:
--   <C-Space>  normal mode -> start selection on the node under the cursor
--   <C-Space>  visual mode -> expand selection to the enclosing parent node
--   <BS>       visual mode -> shrink selection back to the previous range

local M = {}

-- Per-buffer stack of selected ranges. Each entry is { srow, scol, erow, ecol }
-- (0-indexed rows/cols, ecol exclusive — matching `node:range()`). Top of the
-- stack is the current selection; expand pushes, shrink pops.
local stacks = {}

local function get_stack()
	local buf = vim.api.nvim_get_current_buf()
	stacks[buf] = stacks[buf] or {}
	return stacks[buf]
end

-- Read the live visual selection as 0-indexed { srow, scol, erow, ecol } with
-- ecol exclusive, normalized so the start precedes the end.
local function current_selection()
	local _, srow, scol = unpack(vim.fn.getpos("v"))
	local _, erow, ecol = unpack(vim.fn.getpos("."))
	srow, scol, erow, ecol = srow - 1, scol - 1, erow - 1, ecol - 1
	if srow > erow or (srow == erow and scol > ecol) then
		srow, scol, erow, ecol = erow, ecol, srow, scol
	end
	return srow, scol, erow, ecol + 1
end

-- Deterministically (re)create a charwise visual selection covering the given
-- 0-indexed range (ecol exclusive).
local function select_range(srow, scol, erow, ecol)
	-- Leave any active visual mode so the next `v` starts cleanly.
	if vim.fn.mode():match("[vV\22]") then
		vim.cmd("normal! \27")
	end
	vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
	vim.cmd("normal! v")
	vim.api.nvim_win_set_cursor(0, { erow + 1, math.max(ecol - 1, 0) })
end

-- True if range `a` strictly contains range `b` (i.e. is larger).
local function strictly_contains(a, b)
	local asr, asc, aer, aec = a[1], a[2], a[3], a[4]
	local bsr, bsc, ber, bec = b[1], b[2], b[3], b[4]
	local starts_before = asr < bsr or (asr == bsr and asc <= bsc)
	local ends_after = aer > ber or (aer == ber and aec >= bec)
	local equal = asr == bsr and asc == bsc and aer == ber and aec == bec
	return starts_before and ends_after and not equal
end

function M.init_selection()
	local node = vim.treesitter.get_node()
	if not node then
		return
	end
	local stack = get_stack()
	for i = #stack, 1, -1 do
		stack[i] = nil
	end
	local range = { node:range() }
	table.insert(stack, range)
	select_range(range[1], range[2], range[3], range[4])
end

function M.expand()
	local stack = get_stack()
	if #stack == 0 then
		return M.init_selection()
	end

	local srow, scol, erow, ecol = current_selection()
	local cur = { srow, scol, erow, ecol }
	local node = vim.treesitter.get_node({ pos = { srow, scol } })
	while node do
		local range = { node:range() }
		if strictly_contains(range, cur) then
			table.insert(stack, range)
			select_range(range[1], range[2], range[3], range[4])
			return
		end
		node = node:parent()
	end
	-- Already at the root: keep the current selection.
end

function M.shrink()
	local stack = get_stack()
	if #stack <= 1 then
		return
	end
	stack[#stack] = nil
	local range = stack[#stack]
	select_range(range[1], range[2], range[3], range[4])
end

vim.keymap.set("n", "<C-Space>", M.init_selection, { desc = "TS: start incremental selection" })
vim.keymap.set("x", "<C-Space>", M.expand, { desc = "TS: expand selection to parent node" })
vim.keymap.set("x", "<BS>", M.shrink, { desc = "TS: shrink selection to child node" })
-- Terminals frequently deliver Ctrl+Space as <C-@>/<Nul>; alias for compatibility.
vim.keymap.set("n", "<C-@>", M.init_selection, { desc = "TS: start incremental selection" })
vim.keymap.set("x", "<C-@>", M.expand, { desc = "TS: expand selection to parent node" })

return M
