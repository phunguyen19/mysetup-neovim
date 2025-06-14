return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- import lspconfig plugin
		local lspconfig = require("lspconfig")

		-- import mason_lspconfig plugin
		local mason_lspconfig = require("mason-lspconfig")

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
			end,
		})

		-- 1) start from the “vanilla” LSP capabilities…
		local default_caps = vim.lsp.protocol.make_client_capabilities()
		-- 2) feed _that_ into nvim-cmp’s helper…
		local capabilities = require("cmp_nvim_lsp").default_capabilities(default_caps)
		-- …and finally force every server to use UTF-16 for offsets:
		capabilities.offsetEncoding = { "utf-16" }

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		vim.diagnostic.config({
			-- signs = {
			-- 	text = {
			-- 		[vim.diagnostic.severity.ERROR] = signs.Error,
			-- 		[vim.diagnostic.severity.WARN] = signs.Warn,
			-- 		[vim.diagnostic.severity.HINT] = signs.Hint,
			-- 		[vim.diagnostic.severity.INFO] = signs.Info,
			-- 	},
			-- },
			virtual_text = true, -- Enable virtual text (messages next to code)
			float = {
				source = true, -- Show source in floating window
			},
			severity_sort = true, -- Sort diagnostics by severity
		})

		-- Monkey-patch make_position_params to always supply an encoding
		do
			local orig = vim.lsp.util.make_position_params
			vim.lsp.util.make_position_params = function(context, encoding)
				if not encoding then
					-- Grab the first attached client’s encoding (or default to utf-16)
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					encoding = (clients[1] and clients[1].offset_encoding and clients[1].offset_encoding[1]) or "utf-16"
				end
				return orig(context, encoding)
			end
		end

		lspconfig.eslint.setup({
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = true

				-- Disable eslint as formatter if you're using prettier through conform.nvim
				if vim.fn.executable("prettier") == 1 then
					client.server_capabilities.documentFormattingProvider = false
				end

				-- Force ESLint to run on save
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = function()
						vim.cmd("EslintFixAll")
					end,
				})
			end,
			settings = {
				workingDirectory = { mode = "auto" }, -- Try "auto" again
				format = true,
				codeActionOnSave = {
					enable = true,
					mode = "all",
				},
				-- More comprehensive root patterns
				rootDirectory = {
					".eslintrc",
					".eslintrc.js",
					".eslintrc.json",
					".eslintrc.yaml",
					".eslintrc.yml",
					"package.json",
				},
				-- Add this to help with config discovery
				useESLintClass = false,
				experimental = {
					useFlatConfig = false,
				},
			},
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
			-- Add this to help with project root detection
			root_dir = require("lspconfig.util").find_git_ancestor,
		})

		-- Add this near the end of the config function
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

			-- Try to find eslint config files
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
