return {
	{ "nvim-lua/plenary.nvim" },
	{
		"ThePrimeagen/git-worktree.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		config = function()
			require("git-worktree").setup()

			-- load the Telescope extension
			require("telescope").load_extension("git_worktree")

			local wk = vim.keymap.set
			-- Switch worktree: Telescope picker
			wk("n", "<leader>gww", function()
				require("telescope").extensions.git_worktree.git_worktrees()
			end, { desc = "🔀 Switch Git worktree" })

			-- Create new worktree: Telescope picker
			wk("n", "<leader>gwn", function()
				require("telescope").extensions.git_worktree.create_git_worktree()
			end, { desc = "➕ New Git worktree" })

			-- Delete worktree: Telescope picker
			wk("n", "<leader>gwd", function()
				require("telescope").extensions.git_worktree.delete_git_worktree()
			end, { desc = "🗑️  Delete Git worktree" })
		end,
	},
}
