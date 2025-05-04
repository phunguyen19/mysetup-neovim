-- lua/augment_apply/init.lua
-- your module; returns a table with `setup()` and `apply_code_block()`
local M = {}

function M.apply_code_block()
	local s_pos = vim.fn.getpos("'<")
	local e_pos = vim.fn.getpos("'>")
	local start_line, end_line = s_pos[2], e_pos[2]

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	if #lines < 3 then
		return vim.api.nvim_err_writeln("Selection too small")
	end

	-- metadata on first line
	local info = lines[1]
	local path, mode = info:match("path=([^%s]+)%s+mode=([^%s]+)")
	if not path or not mode then
		return vim.api.nvim_err_writeln("Expected: path=… mode=…")
	end

	-- strip fences
	table.remove(lines, #lines)
	table.remove(lines, 1)

	local function edit_and_write(fn)
		-- Check if path is relative and convert to absolute if needed
		if not path:match("^/") then
			path = vim.fn.fnamemodify(vim.fn.getcwd() .. "/" .. path, ":p")
		end

		-- Ensure directory exists
		local dir = vim.fn.fnamemodify(path, ":h")
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
			print("Created directory: " .. dir)
		end

		-- Ensure file exists
		if vim.fn.filereadable(path) == 0 then
			vim.fn.writefile({}, path)
			print("Created file: " .. path)
		end

		vim.cmd("edit " .. path)
		fn()
		vim.cmd("write")
	end

	if mode == "EDIT" then
		edit_and_write(function()
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		end)
	elseif mode == "APPEND" then
		edit_and_write(function()
			local last = vim.api.nvim_buf_line_count(0)
			vim.api.nvim_buf_set_lines(0, last, last, false, lines)
		end)
	elseif mode == "PREPEND" then
		edit_and_write(function()
			vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
		end)
	else
		return vim.api.nvim_err_writeln("Unknown mode: " .. mode)
	end

	vim.api.nvim_out_write(("Applied → %s (%s)\n"):format(path, mode))
end

function M.setup()
	-- Create command for applying code blocks
	vim.api.nvim_create_user_command("AugmentApply", function()
		-- This will work when text is already selected in visual mode
		M.apply_code_block()
	end, { desc = "Apply selected code block to file", range = true })

	-- Create key mapping to apply :'<,'>AugmentApply
	vim.keymap.set(
		"v",
		"<leader>aa",
		":AugmentApply<CR>",
		{ desc = "Apply selected code block to file", noremap = true, silent = true }
	)
end

return M
