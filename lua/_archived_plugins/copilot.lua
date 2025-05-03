return {
	{
		"github/copilot.vim",
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim" },
		},
		config = function()
			require("CopilotChat").setup({
				window = { width = 80 },
			})

			-- Keymaps for CopilotChat

			-- Chat commands (using different keybindings to avoid conflicts)
			vim.keymap.set("n", "<leader>cc", ":CopilotChat<CR>", { desc = "Copilot chat" })
			vim.keymap.set("n", "<leader>cn", ":CopilotChatNew<CR>", { desc = "Copilot new chat" })
			vim.keymap.set("n", "<leader>ct", ":CopilotChatToggle<CR>", { desc = "Copilot toggle chat" })
		end,
	},
}
