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

return M
