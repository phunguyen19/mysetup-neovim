return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
		"nvim-telescope/telescope-live-grep-args.nvim",
	},
	config = function()
		local telescope = require("telescope")

		telescope.setup({
			defaults = {
				preview = true,

				-- Use default config is better than "smart"
				-- path_display = { "smart" },

				-- Customize the width for the window
				layout_config = {
					vertical = { width = 0.8 },
				},
			},
		})

		telescope.load_extension("fzf")
		require("telescope").load_extension("live_grep_args")

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		-- Files
		local fuzzyhiddencmd = "<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files,-u<cr>"
		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
		keymap.set("n", "<leader>fu", fuzzyhiddencmd, { desc = "Fuzzy incl. hidden and ignore" })
		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy recent files" })

		-- Jump
		keymap.set("n", "<leader>fj", "<cmd>Telescope jumplist<cr>", { desc = "Find jump list" })

		-- Quickfix list
		keymap.set("n", "<leader>fqq", "<cmd>Telescope quickfix<cr>", { desc = "Find quickfix" })
		keymap.set("n", "<leader>fqh", "<cmd>Telescope quickfixhistory<cr>", { desc = "Find quickfix history" })

		-- Grep
		local livegrepargs = ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>"
		keymap.set("n", "<leader>fgg", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		keymap.set("n", "<leader>fga", livegrepargs, { desc = "live_grep_args" })

		-- Git
		keymap.set("n", "<leader>fgs", "<cmd>Telescope git_status<cr>", { desc = "Telescope git_status" })
		keymap.set("n", "<leader>fgb", "<cmd>Telescope git_bcommits<cr>", { desc = "Telescope git_bcommits" })

		-- Buffer
		local fuzzycurrbuf = "<cmd>Telescope current_buffer_fuzzy_find<cr>"
		keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Telescope buffers" })
		keymap.set("n", "<leader>fc", fuzzycurrbuf, { desc = "Fuzzy current buffer" })

		-- Todo
		keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
	end,
}

---
