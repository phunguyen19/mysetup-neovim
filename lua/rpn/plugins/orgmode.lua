return {
	{
		"nvim-orgmode/orgmode",
		event = "VeryLazy",
		ft = { "org" },
		config = function()
			-- orgmode installs and manages its own `org` treesitter parser
			-- (not through tree-sitter-manager)
			require("orgmode").setup({
				org_agenda_files = "~/org/**/*",
				org_default_notes_file = "~/org/refile.org",
			})
		end,
	},
	{
		"chipsenkbeil/org-roam.nvim",
		tag = "0.2.0",
		dependencies = { "nvim-orgmode/orgmode" },
		event = "VeryLazy",
		config = function()
			-- default keymaps under <leader>n (nf find, ni insert, nc capture, nl backlinks, nd dailies)
			require("org-roam").setup({
				directory = "~/org/roam",
				org_files = { "~/org/*.org" },
			})
		end,
	},
}
