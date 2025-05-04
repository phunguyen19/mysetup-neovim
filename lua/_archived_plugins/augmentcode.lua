return {
	"augmentcode/augment.vim",
	config = function()
		-- Disable auto-complete to use copilot for auto-complete
		-- 1) disable the entire suggestion engine:
		vim.cmd("Augment disable")
		-- 2) turn off Augment’s Tab-to-accept mapping:
		vim.g.augment_disable_tab_mapping = true

		-- Chat commands
		vim.keymap.set("n", "<leader>ac", ":Augment chat<CR>", { desc = "Augment chat" })
		vim.keymap.set("v", "<leader>ac", ":'<,'>Augment chat<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<leader>an", ":Augment chat-new<CR>", { desc = "Augment new chat" })
		vim.keymap.set("n", "<leader>at", ":Augment chat-toggle<CR>", { desc = "Augment toggle chat" })

		-- Accept completion with Ctrl-y
		vim.keymap.set("i", "<C-y>", "<cmd>call augment#Accept()<cr>", { desc = "Accept Augment suggestion" })

		-- grab the raw string, defaulting to empty
		local raw = os.getenv("AUGMENT_WORKSPACES") or ""

		-- split on ':' into a Lua table
		local folders = {}
		for path in string.gmatch(raw, "[^:]+") do
			-- expand '~' to $HOME
			path = vim.fn.expand(path)
			table.insert(folders, path)
		end

		-- only set if we actually got something
		if #folders > 0 then
			vim.g.augment_workspace_folders = folders
		end
	end,
}
