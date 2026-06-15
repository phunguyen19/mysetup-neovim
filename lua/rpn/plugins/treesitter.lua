return {
	"romus204/tree-sitter-manager.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		require("tree-sitter-manager").setup({
			auto_install = false,
			highlight = true, -- enable native treesitter highlighting for all installed parsers
			-- parsers compiled into stdpath("data")/site/parser (default)
			ensure_installed = {
				"bash",
				"c",
				"css",
				"dockerfile",
				"gitignore",
				"go",
				"graphql",
				"hcl",
				"html",
				"http",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"prisma",
				"proto",
				"query",
				"rust",
				"sql",
				"svelte",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			},
		})

		-- Auto-close/rename tags. Previously enabled via nvim-treesitter's
		-- `autotag` option (no longer functional); now configured standalone.
		require("nvim-ts-autotag").setup()
	end,
}
