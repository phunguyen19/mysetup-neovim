-- Things 3 access: reads through the AppleScript dictionary (jxa/read.js), writes
-- through the things:/// URL scheme (jxa/open.js). Never touches the Things database.
-- Every call is async and reports through `cb(err, result)` on the main loop.

local config = require("rpn.things.config")
local model = require("rpn.things.model")
local token = require("rpn.things.token")
local url = require("rpn.things.url")

local M = {}

local JXA_DIR = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/jxa"

local LIST_SOURCES = {
	inbox = "TMInboxListSource",
	today = "TMTodayListSource",
	anytime = "TMNextListSource",
	upcoming = "TMCalendarListSource",
	someday = "TMSomedayListSource",
}

M.VIEWS = { "today", "inbox", "upcoming", "anytime", "someday", "logbook" }

local function run(argv, stdin, cb)
	vim.system(argv, { text = true, stdin = stdin }, function(res)
		vim.schedule(function()
			if res.code ~= 0 then
				local stderr = vim.trim(res.stderr or "")
				return cb(stderr ~= "" and stderr or ("exit code " .. res.code))
			end
			cb(nil, res.stdout)
		end)
	end)
end

local transport = {
	read = function(args, cb)
		run(vim.list_extend({ "osascript", "-l", "JavaScript", JXA_DIR .. "/read.js" }, args), nil, cb)
	end,
	-- stdin, not argv: argv is visible to every local process via `ps`.
	open = function(target, cb)
		run({ "osascript", "-l", "JavaScript", JXA_DIR .. "/open.js" }, target, cb)
	end,
}

-- Swaps the process layer (tests); returns the previous one.
function M.set_transport(t)
	local previous = transport
	transport = t
	return previous
end

function M.redact(msg, secret)
	msg = tostring(msg):gsub("auth%-token=[^&%s]*", "auth-token=REDACTED")
	if secret and secret ~= "" then
		msg = msg:gsub(vim.pesc(secret), "REDACTED"):gsub(vim.pesc(url.encode(secret)), "REDACTED")
	end
	return msg
end

local function notify_error(err)
	if err then
		vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
	end
end

local function read(args, decode, cb)
	transport.read(args, function(err, out)
		if err then
			return cb("Things read failed: " .. err)
		end
		local ok, data = pcall(vim.json.decode, out, { luanil = { object = true, array = true } })
		if not ok or type(data) ~= "table" then
			return cb("Things returned unreadable data")
		end
		cb(nil, decode(data))
	end)
end

local function identity(x)
	return x
end

local function is_id(s)
	return type(s) == "string" and s:match("^[%w%-]+$") ~= nil
end

function M.list(view, cb)
	if view == "logbook" then
		return read({ "logbook", tostring(config.values.logbook_limit) }, model.todos, cb)
	end
	local source = LIST_SOURCES[view]
	if not source then
		return cb("unknown Things view: " .. tostring(view))
	end
	read({ "list", source }, model.todos, cb)
end

-- `kind` is "project" or "area" (by id) or "tag" (by name).
function M.container(kind, key, cb)
	if kind == "tag" then
		if type(key) ~= "string" or key == "" then
			return cb("invalid tag")
		end
	elseif kind ~= "project" and kind ~= "area" then
		return cb("unknown container: " .. tostring(kind))
	elseif not is_id(key) then
		return cb("invalid " .. kind .. " id")
	end
	read({ kind, key }, model.todos, cb)
end

function M.open_todos(cb)
	read({ "open" }, model.todos, cb)
end

-- { id, name, area }
function M.projects(cb)
	read({ "projects" }, identity, cb)
end

-- { id, name }
function M.areas(cb)
	read({ "areas" }, identity, cb)
end

-- tag names
function M.tags(cb)
	read({ "tags" }, identity, cb)
end

local function open(target, secret, cb)
	transport.open(target, function(err)
		if err then
			return cb("Things write failed: " .. M.redact(err, secret))
		end
		cb(nil)
	end)
end

local function open_authorized(build, cb)
	token.get(function(secret, err)
		if not secret then
			return cb(err)
		end
		local target, build_err = build(secret)
		if not target then
			return cb(build_err)
		end
		open(target, secret, cb)
	end)
end

-- Writes take an optional `cb(err)`; without one, errors are notified.

function M.add(todo, cb)
	cb = cb or notify_error
	local target, err = url.add(todo)
	if not target then
		return cb(err)
	end
	open(target, nil, cb)
end

function M.add_project(project, cb)
	cb = cb or notify_error
	local target, err = url.add_project(project)
	if not target then
		return cb(err)
	end
	open(target, nil, cb)
end

-- `item` is a to-do or project as returned by the reads ({ id, kind }).
function M.update(item, changes, cb)
	local build = item.kind == "project" and url.update_project or url.update
	open_authorized(function(secret)
		return build(item.id, changes, secret)
	end, cb or notify_error)
end

-- `updates` is a list of { id, kind, changes }, applied in one call.
function M.update_many(updates, cb)
	open_authorized(function(secret)
		return url.update_many(updates, secret)
	end, cb or notify_error)
end

-- `target` is an item ID or a built-in list name.
function M.show(target, cb)
	cb = cb or notify_error
	local link, err = url.show(target)
	if not link then
		return cb(err)
	end
	open(link, nil, cb)
end

return M
