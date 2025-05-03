return {
	"augmentcode/augment.vim",
	config = function()
		-- Chat commands
		vim.keymap.set("n", "<leader>ac", ":Augment chat", { desc = "Augment chat" })
		vim.keymap.set("n", "<leader>an", ":Augment chat-new<CR>", { desc = "Augment new chat" })
		vim.keymap.set("n", "<leader>at", ":Augment chat-toggle<CR>", { desc = "Augment toggle chat" })
		-- What is the different between set n and set v
		-- -- n is normal mode, v is visual mode

		-- Accept completion with Ctrl-y
		vim.keymap.set("i", "<C-y>", "<cmd>call augment#Accept()<cr>", { desc = "Accept Augment suggestion" })

		-- enable modiable chat
		vim.g.augment_chat_modifiable = 1
		-- where is the config above, link to document
		-- https://github.com/augmentcode/augment.vim
	end,
}
