-- Things 3 for Neovim. Reads via AppleScript (JXA), writes via the things:/// URL
-- scheme; the Things database is never opened. setup() only registers commands and
-- keymaps — every other module loads on first use.

local config = require("rpn.things.config")

local M = {}

local function client()
	return require("rpn.things.client")
end

local function view()
	return require("rpn.things.view")
end

local function pickers()
	return require("rpn.things.pickers")
end

local function quick_add()
	vim.ui.input({ prompt = "Things inbox: " }, function(title)
		if title and vim.trim(title) ~= "" then
			M.add(title)
		end
	end)
end

function M.add(title)
	client().add({ title = vim.trim(title) }, function(err)
		if err then
			return vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
		end
		vim.notify("Added to Inbox: " .. vim.trim(title), vim.log.levels.INFO, { title = "Things" })
	end)
end

local function add_project()
	vim.ui.input({ prompt = "New Things project: " }, function(title)
		if title and vim.trim(title) ~= "" then
			client().add_project({ title = vim.trim(title) })
		end
	end)
end

local function reveal()
	local current = vim.api.nvim_buf_get_name(0):match("^things://(%a+)$")
	client().show(current or "today")
end

local function check_token()
	require("rpn.things.token").get(function(_, err)
		if err then
			return vim.notify(
				err
					.. "\n\nThings → Settings → General → Enable Things URLs → Manage → copy token, then:\n"
					.. "  security add-generic-password -s "
					.. config.values.token.keychain_service
					.. ' -a "$USER" -w',
				vim.log.levels.WARN,
				{ title = "Things" }
			)
		end
		vim.notify("Things auth token found", vim.log.levels.INFO, { title = "Things" })
	end)
end

local VIEWS = { "today", "inbox", "upcoming", "anytime", "someday", "logbook" }

local function create_commands()
	local cmd = vim.api.nvim_create_user_command
	cmd("Things", function(o)
		view().open(o.args ~= "" and o.args or "today")
	end, {
		nargs = "?",
		complete = function(lead)
			return vim.tbl_filter(function(v)
				return vim.startswith(v, lead)
			end, VIEWS)
		end,
		desc = "Open a Things list",
	})
	cmd("ThingsAdd", function(o)
		if o.args == "" then
			return quick_add()
		end
		M.add(o.args)
	end, { nargs = "*", desc = "Add a to-do to the Things Inbox" })
	cmd("ThingsCapture", function(o)
		require("rpn.things.capture").capture(o.line1, o.line2)
	end, { range = true, desc = "Capture lines as a Things to-do" })
	cmd("ThingsSearch", function()
		pickers().search()
	end, { desc = "Search open Things to-dos" })
	cmd("ThingsProject", function()
		pickers().project()
	end, { desc = "Open a Things project" })
	cmd("ThingsArea", function()
		pickers().area()
	end, { desc = "Open a Things area" })
	cmd("ThingsTag", function()
		pickers().tag()
	end, { desc = "Open a Things tag" })
	cmd("ThingsTokenCheck", check_token, { desc = "Check the Things auth token is configured" })
end

local function create_keymaps()
	local p = config.values.keymap_prefix
	if not p or p == "" then
		return
	end
	local function map(modes, lhs, rhs, desc)
		vim.keymap.set(modes, p .. lhs, rhs, { desc = "Things: " .. desc })
	end
	for key, v in pairs({ t = "today", i = "inbox", u = "upcoming", n = "anytime", s = "someday", l = "logbook" }) do
		map("n", key, function()
			view().open(v)
		end, v)
	end
	map("n", "p", function()
		pickers().project()
	end, "project")
	map("n", "r", function()
		pickers().area()
	end, "area")
	map("n", "#", function()
		pickers().tag()
	end, "tag")
	map("n", "f", function()
		pickers().search()
	end, "search to-dos")
	map("n", "a", quick_add, "quick add to Inbox")
	map("n", "c", "<cmd>ThingsCapture<cr>", "capture line")
	map("x", "c", ":ThingsCapture<cr>", "capture selection")
	map("n", "P", add_project, "add project")
	map("n", "o", reveal, "open in Things app")
end

function M.setup(opts)
	config.set(opts)
	create_commands()
	create_keymaps()
end

return M
