return {
	"gbprod/substitute.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		-- import substitute module
		local substitute = require("substitute")
		-- what is substitute?
		-- https://github.com/gbprod/substitute.nvim

		-- setup
		substitute.setup()

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		vim.keymap.set("n", "s", substitute.operator, { desc = "Substitute with motion" })
		vim.keymap.set("n", "ss", substitute.line, { desc = "Substitute line" })
		vim.keymap.set("n", "S", substitute.eol, { desc = "Substitute to end of line" })
		vim.keymap.set("x", "s", substitute.visual, { desc = "Substitute in visual mode" })
	end,
}
