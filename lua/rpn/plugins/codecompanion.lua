return {
	"olimorris/codecompanion.nvim",
	config = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		log_level = "DEBUG", -- or "TRACE"
		strategies = {
			chat = {
				adapter = vim.fn.getenv("NVIM_CODECOMPANION_CHAT_STRATEGY_ADAPTER"),
			},
			inline = {
				adapter = vim.fn.getenv("NVIM_CODECOMPANION_INLINE_STRATEGY_ADAPTER"),
			},
		},
		adapters = {
			ollama = function()
				return require("codecompanion.adapters").extend("ollama", {
					env = {
						url = vim.fn.getenv("NVIM_CODECOMPANION_OLLAMA_URL"),
					},
					parameters = {
						sync = true,
					},
				})
			end,
		},
	},
}
