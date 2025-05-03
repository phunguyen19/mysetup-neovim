-- lua/plugins/augment_apply.lua
return {
	{
		-- point at your local plugin folder
		dir = vim.fn.stdpath("config") .. "/lua/augment_apply",
		name = "augment_apply",
		lazy = false, -- load at startup
		priority = 1000, -- load early
		config = function()
			require("augment_apply").setup()
		end,
	},
}
