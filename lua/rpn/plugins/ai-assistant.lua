-- AI assistant plugins configuration
-- Enable plugins based on environment variables:
-- NVIM_AI_ASSISTANT_COMPLETIONS=github_copilot|augment
-- NVIM_AI_ASSISTANT_CHAT=github_copilot|augment|claude
return {
	{
		"github/copilot.vim",
		-- Get enable by TERMINAL env variable NVIM_AI_ASSISTANT_COMPLETIONS=github_copilot
		enabled = vim.env.NVIM_AI_ASSISTANT_COMPLETIONS == "github_copilot",
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		-- Get enable by TERMINAL env variable NVIM_AI_ASSISTANT_CHAT=github_copilot
		enabled = vim.env.NVIM_AI_ASSISTANT_CHAT == "github_copilot",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim" },
		},
		config = function()
			require("CopilotChat").setup({
				window = { width = 80 },
			})

			-- Chat commands (using different keybindings to avoid conflicts)
			vim.keymap.set("n", "<leader>ac", ":CopilotChat<CR>", { desc = "Copilot chat" })
			vim.keymap.set("n", "<leader>at", ":CopilotChatToggle<CR>", { desc = "Copilot toggle chat" })
		end,
	},
	{
		"augmentcode/augment.vim",
		enabled = vim.env.NVIM_AI_ASSISTANT_COMPLETIONS == "augment" or vim.env.NVIM_AI_ASSISTANT_CHAT == "augment",
		config = function()
			-- Set workspace folder to current working directory
			local cwd = vim.uv.cwd()
			vim.g.augment_workspace_folders = { cwd }

			-- Disable auto-complete to use copilot for auto-complete
			vim.g.augment_disable_completions = vim.env.NVIM_AI_ASSISTANT_COMPLETIONS ~= "augment"
			vim.g.augment_disable_tab_mapping = vim.env.NVIM_AI_ASSISTANT_COMPLETIONS ~= "augment"

			if vim.env.NVIM_AI_ASSISTANT_CHAT == "augment" then
				vim.keymap.set("n", "<leader>ac", ":Augment chat<CR>", { desc = "Augment chat" })
        -- stylua: ignore
        vim.keymap.set( "v", "<leader>ac", ":Augment chat<CR>", { desc = "Augment chat buffer", noremap = true, silent = true })
				vim.keymap.set("n", "<leader>an", ":Augment chat-new<CR>", { desc = "Augment new chat" })
				vim.keymap.set("n", "<leader>at", ":Augment chat-toggle<CR>", { desc = "Augment toggle chat" })
				vim.keymap.set("i", "<C-y>", "<cmd>call augment#Accept()<cr>", { desc = "Accept Augment suggestion" })
			end
		end,
	},
	{
		-- Local plugin to apply code suggestions from augment.vim
		enabled = vim.env.NVIM_AI_ASSISTANT_CHAT == "augment",
		dir = vim.fn.stdpath("config") .. "/lua/augment_apply",
		name = "augment_apply",
		lazy = false,
		priority = 1000, -- load early
		config = function()
			require("augment_apply").setup()
		end,
	},
	{
		"coder/claudecode.nvim",
		-- Get enable by TERMINAL env variable NVIM_AI_ASSISTANT_CHAT=claude
		enabled = vim.env.NVIM_AI_ASSISTANT_CHAT == "claude",
		dependencies = { "folke/snacks.nvim" },
		config = true,
		keys = {
			{ "<leader>a", nil, desc = "AI/Claude Code" },
			{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
			{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
			{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
			{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
			{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
			{
				"<leader>as",
				"<cmd>ClaudeCodeTreeAdd<cr>",
				desc = "Add file",
				ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
			},
			-- Diff management
			{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
			{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		},
	},
}
