-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness
local yank = require("rpn.core.yank")

---------------------
-- General Keymaps -------------------

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
-- keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- switch to a specific tab by number.
-- e.g. <leader>t2 to switch to tab 2
-- limit: 1-9, otherwise it will not work
keymap.set("n", "<leader>t", function()
	local tab_number = tonumber(vim.fn.getcharstr()) -- Get user input for tab number
	if tab_number then
		vim.cmd(tab_number .. "tabnext") -- Execute tab switch command
	end
end, { desc = "Go to tab position (press number after)" })

-- move current tab to a specific position
-- e.g. <leader>tm2 to move current tab to position 2
vim.keymap.set("n", "<leader>tm", function()
	-- use a count if given, otherwise ask
	local idx = vim.v.count
	if idx == 0 then
		idx = tonumber(vim.fn.input("Move tab to: ")) or 0
	end
	vim.cmd("tabm " .. idx)
end, { silent = true, noremap = true })

-- Copy file relative
vim.keymap.set(
	"n",
	"<leader>pr",
	[[:let @+ = expand('%') | echo 'Copied: ' . expand('%')<CR>]],
	{ noremap = true, desc = "Copy relative path of current file" }
)

vim.keymap.set("n", "<leader>pa", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("Copied: " .. path)
end, { desc = "Copy absolute path of current file" })

vim.keymap.set("n", "<leader>ya", function()
	yank.yank_path(yank.get_buffer_absolute(), "absolute")
end, { desc = "[Y]ank [A]bsolute path to clipboard" })

vim.keymap.set("n", "<leader>yr", function()
	yank.yank_path(yank.get_buffer_cwd_relative(), "relative")
end, { desc = "[Y]ank [R]elative path to clipboard" })

vim.keymap.set("v", "<leader>ya", function()
	yank.yank_visual_with_path(yank.get_buffer_absolute(), "absolute")
end, { desc = "[Y]ank selection with [A]bsolute path" })

vim.keymap.set("v", "<leader>yr", function()
	yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), "relative")
end, { desc = "[Y]ank selection with [R]elative path" })

vim.keymap.set("n", "<leader>yp", function()
	yank.yank_path(yank.get_project_root(), "project")
end, { desc = "[Y]ank [P]roject path to clipboard" })

vim.keymap.set("n", "<leader>yda", function()
	yank.yank_path(yank.get_buffer_dir_absolute(), "absolute directory")
end, { desc = "[Y]ank [D]irectory [A]bsolute path to clipboard" })

vim.keymap.set("n", "<leader>ydr", function()
	yank.yank_path(yank.get_buffer_dir_cwd_relative(), "relative directory")
end, { desc = "[Y]ank [D]irectory [R]elative path to clipboard" })
