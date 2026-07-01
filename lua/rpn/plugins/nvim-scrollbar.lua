return {
	"petertriho/nvim-scrollbar",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"kevinhwang91/nvim-hlslens",
		"lewis6991/gitsigns.nvim",
	},
	config = function()
		-- hlslens: search match counter + virtual text
		require("hlslens").setup()

		local kopts = { noremap = true, silent = true }
		vim.keymap.set(
			"n",
			"n",
			[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
			kopts
		)
		vim.keymap.set(
			"n",
			"N",
			[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
			kopts
		)
		vim.keymap.set("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
		vim.keymap.set("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
		vim.keymap.set("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
		vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)

		-- scrollbar: handle color from melange palette (dark a.sel = #403A36),
		-- transparent bg means the handle needs an explicit color to be visible.
		require("scrollbar").setup({
			handle = { color = "#403A36" },
			handlers = {
				cursor = true,
				diagnostic = true,
				gitsigns = true,
				handle = true,
				search = true,
			},
		})

		-- handlers that must be wired to their source plugins
		require("scrollbar.handlers.search").setup()
		require("scrollbar.handlers.gitsigns").setup()
	end,
}
