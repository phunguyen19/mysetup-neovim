-- https://github.com/hedyhli/outline.nvim
-- A sidebar with a tree-like outline of symbols from your code, powered by LSP
--
-- There are also some related plugins like `aerial.nvim` found below
-- https://github.com/hedyhli/outline.nvim?tab=readme-ov-file#related-plugins
--
return {
	"hedyhli/outline.nvim",
	lazy = true,
	cmd = { "Outline", "OutlineOpen" },
	keys = { -- Example mapping to toggle outline
		{ "<leader>oo", "<cmd>Outline<CR>", desc = "Toggle outline" },
	},
	opts = {
		outline_window = {
			-- Vim options for the outline window
			show_numbers = true,
			show_relative_numbers = true,
			width = 25,
		},

		symbol_folding = {
			-- Unfold entire symbol tree by default with false, otherwise enter a
			-- number starting from 1
			autofold_depth = 1,
			-- autofold_depth = 1,
		},
	},
}
