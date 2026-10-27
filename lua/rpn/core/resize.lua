-- Resize the left/right sidebar from any window, without focusing it.
local M = {}

local SIDEBAR_FT = {
	NvimTree = true,
	Outline = true,
	["context-outline"] = true,
	trouble = true,
}

local MIN_WIDTH = 10

local function find_sidebar(side)
	local best, best_edge
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_config(win).relative == "" then
			local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
			if SIDEBAR_FT[ft] then
				local col = vim.api.nvim_win_get_position(win)[2]
				if side == "left" then
					if not best_edge or col < best_edge then
						best, best_edge = win, col
					end
				else
					local right = col + vim.api.nvim_win_get_width(win)
					if not best_edge or right > best_edge then
						best, best_edge = win, right
					end
				end
			end
		end
	end
	return best
end

function M.resize_sidebar(side, delta)
	local win = find_sidebar(side)
	if not win then
		vim.notify("No " .. side .. " sidebar open", vim.log.levels.INFO)
		return
	end
	local width = vim.api.nvim_win_get_width(win)
	vim.api.nvim_win_set_width(win, math.max(MIN_WIDTH, width + delta))
end

-- Move a border of the current window in direction `dir` (h/j/k/l), tmux-style.
-- Prefers the border on that side (so the window expands that way); at the
-- edge of the screen it moves the opposite border instead (window shrinks).
local AXIS = {
	h = { back = "h", fwd = "l", size = "width", fix = "winfixwidth" },
	l = { back = "h", fwd = "l", size = "width", fix = "winfixwidth" },
	k = { back = "k", fwd = "j", size = "height", fix = "winfixheight" },
	j = { back = "k", fwd = "j", size = "height", fix = "winfixheight" },
}

local function neighbor(win, d)
	return vim.api.nvim_win_call(win, function()
		local id = vim.fn.win_getid(vim.fn.winnr(d))
		return id ~= win and id or nil
	end)
end

function M.move_border(dir, step)
	local cur = vim.api.nvim_get_current_win()
	if vim.api.nvim_win_get_config(cur).relative ~= "" then
		return
	end
	local a = AXIS[dir]
	local back, fwd = neighbor(cur, a.back), neighbor(cur, a.fwd)
	local forward = dir == a.fwd

	-- Every border is the right/bottom edge of some window `w`; vim moves
	-- that edge when `w` is resized. `other` is the window across it.
	local w, other, delta
	if forward then
		if fwd then
			w, other, delta = cur, fwd, step -- expand toward dir
		elseif back then
			w, other, delta = back, cur, step -- at edge: shrink from the back
		end
	else
		if back then
			w, other, delta = back, cur, -step -- expand toward dir
		elseif fwd then
			w, other, delta = cur, fwd, -step -- at edge: shrink from the front
		end
	end
	if not w then
		return
	end

	-- Pin every other window so only the two around this border change.
	local saved = {}
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		saved[win] = vim.wo[win][a.fix]
		vim.wo[win][a.fix] = win ~= other
	end
	if a.size == "width" then
		vim.api.nvim_win_set_width(w, math.max(1, vim.api.nvim_win_get_width(w) + delta))
	else
		vim.api.nvim_win_set_height(w, math.max(1, vim.api.nvim_win_get_height(w) + delta))
	end
	for win, v in pairs(saved) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win][a.fix] = v
		end
	end
end

return M
