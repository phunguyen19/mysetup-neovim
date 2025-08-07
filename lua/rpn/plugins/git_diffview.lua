return {
	"sindrets/diffview.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		-- Basic setup with default options
		require("diffview").setup({
			enhanced_diff_hl = true, -- highlight word diff
			use_icons = true, -- applies your icon set to the UI
			icons = {
				folder_closed = "",
				folder_open = "",
			},
			file_panel = {
				listing_style = "tree", -- (optional) 'list' or 'tree'
				tree_options = { -- (optional) when using 'tree'
					flatten_dirs = true,
					folder_statuses = "only_folded",
				},
				win_config = { -- ← everything goes in here now
					position = "bottom", -- 'left' | 'right' | 'top' | 'bottom'
					width = 40, -- width when pos='left' or 'right'
					height = 16, -- height when pos='top'  or 'bottom'
					win_opts = {}, -- any `nvim_win_set_*` opts you like
				},
			},
		})

		-- Keymaps (feel free to tweak to your taste)
		local map = vim.keymap.set
		map("n", "<leader>gdo", "<cmd>DiffviewOpen<CR>", { desc = "Diffview: Open" })
		map("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Diffview: Close" })
		map("n", "<leader>gdf", "<cmd>DiffviewFileHistory %<CR>", { desc = "Diffview: File History" })
		map("n", "<leader>gdF", "<cmd>DiffviewFileHistory<CR>", { desc = "Diffview: Project History" })
	end,
}
