return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- Get default capabilities
		local default_caps = vim.lsp.protocol.make_client_capabilities()
		local capabilities = require("cmp_nvim_lsp").default_capabilities(default_caps)
		capabilities.offsetEncoding = { "utf-16" }

		local keymap = vim.keymap

		-- Set up LSP attach handlers
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }

				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>lD", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		-- Configure diagnostics
		vim.diagnostic.config({
			virtual_text = true,
			float = {
				source = true,
			},
			severity_sort = true,
		})

		-- Monkey-patch for encoding
		do
			local orig = vim.lsp.util.make_position_params
			vim.lsp.util.make_position_params = function(context, encoding)
				if not encoding then
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					encoding = (clients[1] and clients[1].offset_encoding and clients[1].offset_encoding[1]) or "utf-16"
				end
				return orig(context, encoding)
			end
		end

		-- Use the new vim.lsp.config API instead of lspconfig
		vim.lsp.config("eslint", {
			cmd = { "eslint_d" },
			filetypes = {
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
				"vue",
				"svelte",
			},
			root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js" },
			settings = {
				workingDirectory = { mode = "auto" },
				codeActionOnSave = {
					enable = true,
					mode = "all",
				},
				useESLintClass = false,
				experimental = {
					useFlatConfig = false,
				},
			},
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = true

				if vim.fn.executable("prettier") == 1 then
					client.server_capabilities.documentFormattingProvider = false
				end

				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = function()
						vim.cmd("EslintFixAll")
					end,
				})
			end,
			capabilities = capabilities,
		})

		-- Enable the eslint server
		vim.lsp.enable("eslint")

		-- Debug command
		vim.api.nvim_create_user_command("ESLintDebug", function()
			local bufnr = vim.api.nvim_get_current_buf()
			local clients = vim.lsp.get_active_clients({ bufnr = bufnr, name = "eslint" })

			if #clients == 0 then
				print("No ESLint client attached to this buffer")
				return
			end

			local client = clients[1]
			print("ESLint client ID: " .. client.id)
			print("Root directory: " .. client.config.root_dir)
			print("Workspace folders: ")
			for _, folder in ipairs(client.workspace_folders or {}) do
				print("  - " .. folder.name)
			end

			local possible_configs = {
				".eslintrc",
				".eslintrc.js",
				".eslintrc.json",
				".eslintrc.yaml",
				".eslintrc.yml",
			}

			print("Searching for ESLint config files:")
			for _, config in ipairs(possible_configs) do
				local config_path = client.config.root_dir .. "/" .. config
				if vim.fn.filereadable(config_path) == 1 then
					print("  - Found: " .. config_path)
				else
					print("  - Not found: " .. config_path)
				end
			end
		end, {})
	end,
}
