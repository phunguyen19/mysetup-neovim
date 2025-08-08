-- lua/plugins/toggleterm.lua
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	opts = {
		open_mapping = [[<c-\>]], -- toggle last terminal
		shade_terminals = false,
	},
	keys = {
		{ "<leader>teh", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (horizontal)" },
		{ "<leader>tev", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal (vertical)" },
		{ "<leader>tef", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal (float)" },
		{ "<leader>tet", "<cmd>ToggleTerm direction=tab<cr>", desc = "Terminal (tab)" },
	},
}
