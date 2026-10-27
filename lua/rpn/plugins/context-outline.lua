-- Context Outline: browse a project's .context-outline/root.json map in a side panel.
-- Local plugin at ~/dev/personal/context-outline.nvim
return {
	dir = "~/dev/personal/context-outline.nvim",
	name = "context-outline.nvim",
	cmd = { "ContextOutline", "ContextOutlineBuild", "ContextOutlineBuildPrompt", "ContextOutlineReindexPrompt" },
	keys = {
		{ "<leader>co", "<cmd>ContextOutline<CR>", desc = "Toggle context outline" },
	},
	opts = {
		position = "right", -- or "left"
		width = 40,
	},
}
