return {
	"augmentcode/augment.vim",
	config = function()
		-- Chat commands
		vim.keymap.set("n", "<leader>ac", ":Augment chat<CR>", { desc = "Augment chat" })
		-- keymap for chat on selected buffer :'<.'>Augment chat<CR>
		vim.keymap.set("v", "<leader>ac", ":'<.'>Augment chat<CR>", { desc = "Augment chat" })
		vim.keymap.set("n", "<leader>an", ":Augment chat-new<CR>", { desc = "Augment new chat" })
		vim.keymap.set("n", "<leader>at", ":Augment chat-toggle<CR>", { desc = "Augment toggle chat" })

		-- Accept completion with Ctrl-y
		vim.keymap.set("i", "<C-y>", "<cmd>call augment#Accept()<cr>", { desc = "Accept Augment suggestion" })
	end,
}
