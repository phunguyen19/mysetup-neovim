return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")
		local biome_util = require("rpn.utils.biome")

		lint.linters_by_ft = {
			javascript = { "eslint" },
			typescript = { "eslint" },
			javascriptreact = { "eslint" },
			typescriptreact = { "eslint" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				if biome_util.is_biome_project(0) then
					return
				end
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>ll", function()
			if biome_util.is_biome_project(0) then
				return
			end
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
