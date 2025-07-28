return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			automatic_installation = true,

			-- list of servers for mason to install
			ensure_installed = {
				"cssls",
				"eslint",
				"gopls",
				"graphql",
				"html",
				"jsonls",
				"lua_ls",
				"pbls",
				"prismals",
				"pyright",
				"rust_analyzer",
				"terraformls",
				"ts_ls",
				"yamlls",
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- prettier formatter
			},
		})
	end,
}
