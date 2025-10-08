-- lua/plugins/toggleterm.lua
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	opts = {
		open_mapping = [[<c-\>]], -- toggle last terminal
		shade_terminals = false,
	},
	keys = {
		{ "<leader>tt", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal (float)" },
	},
}
