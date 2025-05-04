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

			-- Chat commands (using different keybindings to avoid conflicts)
			vim.keymap.set("n", "<leader>acc", ":CopilotChat<CR>", { desc = "Copilot chat" })
			vim.keymap.set("n", "<leader>act", ":CopilotChatToggle<CR>", { desc = "Copilot toggle chat" })
		end,
	},
	{
		"augmentcode/augment.vim",
		config = function()
			-- Disable auto-complete to use copilot for auto-complete
			-- 1) disable the entire suggestion engine:
			vim.g.augment_disable_completions = true
			-- 2) turn off Augment’s Tab-to-accept mapping:
			vim.g.augment_disable_tab_mapping = true

			-- Chat commands
			vim.keymap.set("n", "<leader>aac", ":Augment chat<CR>", { desc = "Augment chat" })
			vim.keymap.set("v", "<leader>aac", ":'<,'>Augment chat<CR>", { desc = "Argument chat buffer", noremap = true, silent = true })
			vim.keymap.set("n", "<leader>aan", ":Augment chat-new<CR>", { desc = "Augment new chat" })
			vim.keymap.set("n", "<leader>aat", ":Augment chat-toggle<CR>", { desc = "Augment toggle chat" })

			-- Accept completion with Ctrl-y
			vim.keymap.set("i", "<C-y>", "<cmd>call augment#Accept()<cr>", { desc = "Accept Augment suggestion" })

			-- Setup work space
			vim.g.augment_workspace_folders = {
				"~/.config/nvim/",
				"~/Workspaces/Personal/stacks-core",
			}
		end,
	},
}
