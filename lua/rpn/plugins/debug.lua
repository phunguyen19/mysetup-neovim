return {
	"mfussenegger/nvim-dap",
	recommended = true,
	desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",
	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "nvim-neotest/nvim-nio" },
      -- stylua: ignore
      keys = {
        { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
        { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
      },
			opts = {},
		},
		{
			"leoluz/nvim-dap-go",
			ft = { "go" },
			config = function()
				require("dap-go").setup() -- this registers the Go adapter & sensible defaults
			end,
		},
		-- virtual text for the debugger
		-- { "theHamsta/nvim-dap-virtual-text", opts = {} },
	},

  -- stylua: ignore
  keys = {
    { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dI", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dj", function() require("dap").down() end, desc = "Down" },
    { "<leader>dk", function() require("dap").up() end, desc = "Up" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>ds", function() require("dap").session() end, desc = "Session" },
    { "<leader>dx", function() require("dap").terminate() end, desc = "Terminate Session" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets (Show values)" },
  },

	config = function()
		local dap = require("dap")

		-- Setup Mason DAP adapter if available
		local has_mason, mason_dap = pcall(require, "mason-nvim-dap")
		if has_mason and mason_dap.setup then
			mason_dap.setup({
				ensure_installed = { "node-debug2-adapter" },
			})
		end

		-- DAP javscript/typescript
		dap.adapters.node2 = {
			type = "executable",
			command = "node",
			args = {
				vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
			},
		}
		dap.configurations.typescript = {
			{
				name = "[NodeJS] Launch via npm:dev:debug",
				type = "node2",
				request = "launch",
				cwd = vim.fn.getcwd(),
				runtimeExecutable = "npm",
				runtimeArgs = { "run-script", "dev:debug" },
				port = 9229,
				skipFiles = { "<node_internals>/**" },
				sourceMaps = true,
				protocol = "inspector",
			},
			{
				name = "[NodeJS] Attach to process",
				type = "node2",
				request = "attach",
				processId = require("dap.utils").pick_process,
				cwd = vim.fn.getcwd(),
				sourceMaps = true,
				protocol = "inspector",
			},
		}
		dap.configurations.javascript = dap.configurations.typescript

		-- DAP go
		dap.adapters.go = {
			type = "server",
			port = "${port}",
			executable = {
				command = "dlv",
				args = { "dap", "-l", "127.0.0.1:${port}" },
			},
		}
		dap.configurations.go = {
			{
				type = "go",
				name = "[Go] Launch and Debug Current File",
				request = "launch",
				program = "${file}",
			},
			{
				type = "go",
				name = "[Go] Launch and Debug Current Package Tests",
				request = "launch",
				mode = "test",
				program = "${fileDirname}",
			},
			{
				type = "go",
				name = "[Go] Attach to Process",
				request = "attach",
				processId = require("dap.utils").pick_process,
				mode = "local",
			},
		}

		-- Define signs for DAP if not already defined
		-- Define signs for DAP (breakpoints, logpoints, etc.)
		local dap_signs = {
			Breakpoint = { text = "🛑", texthl = "DiagnosticSignError" },
			BreakpointCondition = { text = "◆", texthl = "DiagnosticSignError" },
			BreakpointRejected = { text = "✖", texthl = "DiagnosticSignError" },
			LogPoint = { text = "📝", texthl = "DiagnosticSignInfo" },
			Stopped = { text = "▶", texthl = "DiagnosticSignWarn" },
		}
		for name, sign in pairs(dap_signs) do
			vim.fn.sign_define("Dap" .. name, sign)
		end

		-- Highlight for current line
		vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

		-- Optional: VSCode launch.json support
		local ok, vscode = pcall(require, "dap.ext.vscode")
		if ok then
			local json = require("plenary.json")
			vscode.json_decode = function(str)
				return vim.json.decode(json.json_strip_comments(str))
			end
		end
	end,
}
