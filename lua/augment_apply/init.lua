-- Augment.nvim: A Neovim plugin for applying code blocks of AugmentCode to files
--
-- This plugin allows you to select a code block in visual mode and apply it to a file.
-- It supports different modes like EDIT, APPEND, and PREPEND.
--
-- Usage:
-- 1. Select a code block in visual mode.
-- 2. Use the command `:AugmentApply` or the key mapping `<leader>aa` to apply the code block.
--
-- This plugin will read the metadata from the first line of the selected code block,
--    check the mode, and apply the changes to the specified file.
--
-- This plugin is designed to work with AugmentCode, a tool for managing code blocks.
--
-- Lazy installation:
-- {
-- 	-- point at your local plugin folder
-- 	dir = vim.fn.stdpath("config") .. "/lua/augment_apply",
-- 	name = "augment_apply",
-- 	lazy = false,
-- 	priority = 1000, -- load early
-- 	config = function()
-- 		require("augment_apply").setup()
-- 	end,
-- },

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

		-- Save current buffer and window
		local current_buf = vim.api.nvim_get_current_buf()
		local current_win = vim.api.nvim_get_current_win()

		-- Create a new hidden buffer for the target file
		local target_buf = vim.fn.bufadd(path)
		vim.fn.bufload(target_buf)

		-- Apply the changes to the buffer
		if vim.api.nvim_buf_is_loaded(target_buf) then
			-- Apply the function to modify the buffer
			local ok, err = pcall(function()
				-- Set the buffer as current for the function
				fn(target_buf)

				-- Write the buffer to disk
				if vim.api.nvim_buf_get_option(target_buf, "modified") then
					vim.api.nvim_buf_call(target_buf, function()
						vim.cmd("silent write")
					end)
				end
			end)

			if not ok then
				vim.api.nvim_err_writeln("Error applying changes: " .. err)
			end
		else
			vim.api.nvim_err_writeln("Failed to load buffer for " .. path)
		end
	end

	-- Update the mode handlers to work with the new approach
	if mode == "EDIT" then
		edit_and_write(function(buf)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		end)
	elseif mode == "APPEND" then
		edit_and_write(function(buf)
			local last = vim.api.nvim_buf_line_count(buf)
			vim.api.nvim_buf_set_lines(buf, last, last, false, lines)
		end)
	elseif mode == "PREPEND" then
		edit_and_write(function(buf)
			vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
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
