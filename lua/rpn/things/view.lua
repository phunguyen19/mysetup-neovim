-- List buffers (things://today, things://project/<id>, ...): render, act on the
-- to-do under the cursor, then re-read. Writes render optimistically because the
-- URL scheme gives no confirmation beyond "Things received the URL".

local client = require("rpn.things.client")
local config = require("rpn.things.config")
local model = require("rpn.things.model")

local M = {}

local ns = vim.api.nvim_create_namespace("rpn_things")
local states = {}

local STATUS_BOX = { open = "[ ]", completed = "[x]", canceled = "[-]" }
-- Things draws projects as circles.
local PROJECT_BOX = { open = "( )", completed = "(x)", canceled = "(-)" }

local TITLES = {
	today = "Today",
	inbox = "Inbox",
	upcoming = "Upcoming",
	anytime = "Anytime",
	someday = "Someday",
	logbook = "Logbook",
}

-- What a to-do added from a view inherits, so it lands in that view.
local ADD_DEFAULTS = {
	today = { when = "today" },
	upcoming = { when = "tomorrow" },
	anytime = { when = "anytime" },
	someday = { when = "someday" },
}

local function define_highlights()
	local hl = function(name, opts)
		opts.default = true
		vim.api.nvim_set_hl(0, name, opts)
	end
	hl("ThingsHeader", { link = "Title" })
	hl("ThingsBox", { link = "Delimiter" })
	hl("ThingsDone", { link = "Comment" })
	hl("ThingsStrike", { strikethrough = true })
	hl("ThingsTag", { link = "Special" })
	hl("ThingsWhen", { link = "Constant" })
	hl("ThingsDeadline", { link = "DiagnosticWarn" })
	hl("ThingsOverdue", { link = "DiagnosticError" })
	hl("ThingsMeta", { link = "Comment" })
	hl("ThingsPending", { link = "DiagnosticHint" })
end

-- Pure: turns a view into buffer lines plus decorations, so it can be tested
-- without a window. `opts.hide` drops the column the view is already grouped by.
function M.render(title, todos, opts)
	opts = opts or {}
	local today = opts.today or model.today()
	local header = opts.loading and (title .. " · loading…") or string.format("%s · %d", title, #todos)
	local lines = { header, "" }
	local marks = { { line = 0, col = 0, end_col = #header, hl = "ThingsHeader" } }
	local items = {}

	if #todos == 0 and not opts.loading then
		lines[#lines + 1] = "  (empty)"
		marks[#marks + 1] = { line = #lines - 1, col = 0, end_col = #lines[#lines], hl = "ThingsMeta" }
	end

	for _, todo in ipairs(todos) do
		local boxes = todo.kind == "project" and PROJECT_BOX or STATUS_BOX
		local box = boxes[todo.status] or boxes.open
		local text = string.format("  %s %s", box, todo.title)
		lines[#lines + 1] = text
		local row = #lines - 1
		items[#lines] = todo
		marks[#marks + 1] = { line = row, col = 2, end_col = 5, hl = "ThingsBox" }
		if todo.status ~= "open" then
			marks[#marks + 1] = { line = row, col = 6, end_col = #text, hl = "ThingsDone" }
			marks[#marks + 1] = { line = row, col = 6, end_col = #text, hl = "ThingsStrike" }
		end

		local virt = {}
		local function add(chunk, hl)
			virt[#virt + 1] = { "  " .. chunk, hl }
		end
		for _, tag in ipairs(todo.tags or {}) do
			add("#" .. tag, "ThingsTag")
		end
		if todo.when and todo.when > today and not opts.hide_when then
			add(model.short_date(todo.when, today), "ThingsWhen")
		end
		if todo.deadline then
			add(
				"⚑ " .. model.short_date(todo.deadline, today),
				model.is_overdue(todo, today) and "ThingsOverdue" or "ThingsDeadline"
			)
		end
		if todo.completed_on and todo.status ~= "open" then
			add(model.short_date(todo.completed_on, today), "ThingsMeta")
		end
		if todo.notes and todo.notes ~= "" then
			add("✎", "ThingsMeta")
		end
		local parent
		if opts.hide ~= "project" then
			parent = todo.project or (opts.hide ~= "area" and todo.area or nil)
		end
		if parent then
			add(parent, "ThingsMeta")
		end
		if todo.pending then
			add("(syncing)", "ThingsPending")
		end
		if #virt > 0 then
			marks[#marks + 1] = { line = row, col = 0, virt_text = virt }
		end
	end

	return { lines = lines, marks = marks, items = items }
end

local function draw(buf)
	local state = states[buf]
	if not state or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local out = M.render(state.title, state.todos or {}, {
		loading = state.todos == nil,
		hide = state.hide,
		hide_when = state.view == "today",
	})
	state.items = out.items

	local win = vim.fn.bufwinid(buf)
	local cursor_id
	if win ~= -1 then
		local current = state.items_before and state.items_before[vim.api.nvim_win_get_cursor(win)[1]]
		cursor_id = current and current.id
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, out.lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].modified = false
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, m in ipairs(out.marks) do
		if m.virt_text then
			vim.api.nvim_buf_set_extmark(buf, ns, m.line, m.col, { virt_text = m.virt_text, virt_text_pos = "eol" })
		else
			vim.api.nvim_buf_set_extmark(buf, ns, m.line, m.col, { end_col = m.end_col, hl_group = m.hl })
		end
	end

	if win ~= -1 and cursor_id then
		for lnum, item in pairs(out.items) do
			if item.id == cursor_id then
				vim.api.nvim_win_set_cursor(win, { lnum, 0 })
				break
			end
		end
	end
	state.items_before = out.items
end

function M.refresh(buf)
	local state = states[buf]
	if not state then
		return
	end
	state.seq = state.seq + 1
	local seq = state.seq
	state.fetch(function(err, todos)
		-- A slower, older read must not overwrite a newer one.
		if not states[buf] or states[buf].seq ~= seq then
			return
		end
		if err then
			return vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
		end
		state.todos = todos
		state.fetched_at = vim.uv.now()
		draw(buf)
	end)
end

local function refresh_soon(buf)
	vim.defer_fn(function()
		M.refresh(buf)
	end, config.values.refresh_delay_ms)
end

local function item_at(buf, lnum)
	local state = states[buf]
	return state and state.items and state.items[lnum]
end

local function selected_items(buf)
	local first, last = vim.fn.line("v"), vim.fn.line(".")
	if first > last then
		first, last = last, first
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
	local items = {}
	for lnum = first, last do
		local item = item_at(buf, lnum)
		if item then
			items[#items + 1] = item
		end
	end
	return items
end

local function targets(buf, visual)
	if visual then
		return selected_items(buf)
	end
	local item = item_at(buf, vim.api.nvim_win_get_cursor(0)[1])
	return item and { item } or {}
end

-- Applies `changes_for(item)` to every target, optimistically via `optimistic(item)`.
-- Rolls the optimistic state back if Things can't be reached.
local function apply(buf, items, changes_for, optimistic)
	if #items == 0 then
		return
	end
	local updates, snapshots = {}, {}
	for _, item in ipairs(items) do
		local changes = changes_for(item)
		if changes then
			updates[#updates + 1] = { id = item.id, kind = item.kind, changes = changes }
			snapshots[#snapshots + 1] = { item = item, copy = vim.deepcopy(item) }
			if optimistic then
				optimistic(item)
			end
			item.pending = true
		end
	end
	if #updates == 0 then
		return
	end
	draw(buf)

	local function done(err)
		if err then
			for _, s in ipairs(snapshots) do
				for k in pairs(s.item) do
					s.item[k] = nil
				end
				for k, v in pairs(s.copy) do
					s.item[k] = v
				end
			end
			draw(buf)
			return vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
		end
		refresh_soon(buf)
	end

	if #updates == 1 then
		client.update(updates[1], updates[1].changes, done)
	else
		client.update_many(updates, done)
	end
end

local function set_status(buf, items, status_for)
	local state = states[buf]
	local undo = {}
	apply(buf, items, function(item)
		local to = status_for(item)
		local changes = model.status_changes(item.status, to)
		if changes then
			undo[#undo + 1] = { id = item.id, from = to, to = item.status }
		end
		return changes
	end, function(item)
		item.status = status_for(item)
	end)
	if #undo > 0 then
		state.undo = undo
	end
end

local function toggle_complete(buf, visual)
	set_status(buf, targets(buf, visual), function(item)
		return item.status == "open" and "completed" or "open"
	end)
end

local function cancel(buf, visual)
	set_status(buf, targets(buf, visual), function()
		return "canceled"
	end)
end

local function undo(buf)
	local state = states[buf]
	local steps = state.undo
	if not steps then
		return vim.notify("Nothing to undo", vim.log.levels.INFO, { title = "Things" })
	end
	state.undo = nil
	local by_id = {}
	for _, step in ipairs(steps) do
		by_id[step.id] = step
	end
	local items = vim.tbl_filter(function(item)
		return by_id[item.id] ~= nil
	end, vim.tbl_values(state.items or {}))
	if #items < #steps then
		vim.notify("Some to-dos left this list; undo them in Things", vim.log.levels.WARN, { title = "Things" })
	end
	-- Transitions are recorded explicitly: the items may have been re-read since.
	apply(buf, items, function(item)
		return model.status_changes(by_id[item.id].from, by_id[item.id].to)
	end, function(item)
		item.status = by_id[item.id].to
	end)
end

local function schedule(buf, visual)
	local items = targets(buf, visual)
	if #items == 0 then
		return
	end
	local choices = vim.list_extend(vim.deepcopy(model.WHEN), { "date…" })
	vim.ui.select(choices, { prompt = "When" }, function(choice)
		if not choice then
			return
		end
		local function set(when)
			apply(buf, items, function()
				return { when = when }
			end)
		end
		if choice ~= "date…" then
			return set(choice)
		end
		vim.ui.input({ prompt = "When (YYYY-MM-DD or 'next friday'): " }, function(input)
			if input and vim.trim(input) ~= "" then
				set(vim.trim(input))
			end
		end)
	end)
end

local function deadline(buf, visual)
	local items = targets(buf, visual)
	if #items == 0 then
		return
	end
	vim.ui.input({ prompt = "Deadline (empty clears): ", default = items[1].deadline or "" }, function(input)
		if input == nil then
			return
		end
		local value = vim.trim(input)
		apply(buf, items, function()
			return { deadline = value }
		end, function(item)
			item.deadline = value ~= "" and value or nil
		end)
	end)
end

local tag_names = {}

-- Completes the last comma-separated entry of `lead` against `names`.
function M.tag_completions(lead, names)
	local head, last = lead:match("^(.*,%s*)([^,]*)$")
	head, last = head or "", last or lead
	local out = {}
	for _, tag in ipairs(names) do
		if vim.startswith(tag:lower(), vim.trim(last):lower()) then
			out[#out + 1] = head .. tag
		end
	end
	return out
end

-- customlist completion for the tag prompt.
function M.complete_tags(lead)
	return M.tag_completions(lead, tag_names)
end

local function edit_tags(buf, visual)
	local items = targets(buf, visual)
	if #items == 0 then
		return
	end
	client.tags(function(err, names)
		if err then
			return vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
		end
		tag_names = names
		vim.ui.input({
			prompt = "Tags (comma separated, must exist in Things): ",
			default = table.concat(items[1].tags or {}, ", "),
			completion = "customlist,v:lua.require'rpn.things.view'.complete_tags",
		}, function(input)
			if input == nil then
				return
			end
			local tags = {}
			for tag in input:gmatch("[^,]+") do
				if vim.trim(tag) ~= "" then
					tags[#tags + 1] = vim.trim(tag)
				end
			end
			apply(buf, items, function()
				return { tags = tags }
			end, function(item)
				item.tags = tags
			end)
		end)
	end)
end

local function move(buf, visual)
	local items = targets(buf, visual)
	if #items == 0 then
		return
	end
	require("rpn.things.pickers").destination(function(dest)
		apply(buf, items, function()
			return { list_id = dest.id }
		end)
	end)
end

local function add(buf, full)
	local state = states[buf]
	local defaults = vim.deepcopy(state.add_defaults or {})
	if full then
		return require("rpn.things.editor").create(defaults, function()
			refresh_soon(buf)
		end)
	end
	vim.ui.input({ prompt = "New to-do: " }, function(title)
		if not title or vim.trim(title) == "" then
			return
		end
		defaults.title = vim.trim(title)
		client.add(defaults, function(err)
			if err then
				return vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
			end
			refresh_soon(buf)
		end)
	end)
end

local function float(lines, title)
	local fbuf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
	vim.bo[fbuf].filetype = "markdown"
	vim.bo[fbuf].modifiable = false
	local width = 20
	for _, l in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(l))
	end
	local win = vim.api.nvim_open_win(fbuf, true, {
		relative = "cursor",
		row = 1,
		col = 0,
		width = math.min(width + 2, math.floor(vim.o.columns * 0.8)),
		height = math.min(#lines, math.floor(vim.o.lines * 0.6)),
		border = "rounded",
		title = title,
		style = "minimal",
	})
	vim.wo[win].wrap = true
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = fbuf, nowait = true })
	end
end

local function peek(buf)
	local item = item_at(buf, vim.api.nvim_win_get_cursor(0)[1])
	if not item then
		return
	end
	local lines = vim.split(item.notes ~= "" and item.notes or "(no notes)", "\n")
	float(lines, " " .. item.title .. " ")
end

local HELP = {
	"x        toggle complete         X   cancel",
	"u        undo last complete/cancel",
	"a / A    add to-do (quick / editor)",
	"<CR>     edit in float (:w saves)",
	"K        peek notes",
	"s        schedule (when)         d   deadline",
	"t        tags                    m   move to project/area",
	"o        reveal in Things        R   refresh",
	"gi gt gu gn gs gl   inbox/today/upcoming/anytime/someday/logbook",
	"q        close",
	"",
	"Visual mode: x X s d t m apply to every selected to-do.",
	"Deleting isn't possible via things:/// — cancel (X) instead.",
	"Checklists aren't readable via AppleScript; the editor can only append.",
}

local function set_keymaps(buf)
	local function map(modes, lhs, fn, desc)
		vim.keymap.set(modes, lhs, fn, { buffer = buf, nowait = true, silent = true, desc = "Things: " .. desc })
	end
	local function both(lhs, fn, desc)
		map("n", lhs, function()
			fn(buf, false)
		end, desc)
		map("x", lhs, function()
			fn(buf, true)
		end, desc)
	end

	both("x", toggle_complete, "toggle complete")
	both("X", cancel, "cancel")
	both("s", schedule, "schedule")
	both("d", deadline, "deadline")
	both("t", edit_tags, "tags")
	both("m", move, "move")
	map("n", "u", function()
		undo(buf)
	end, "undo complete/cancel")
	map("n", "a", function()
		add(buf, false)
	end, "add")
	map("n", "A", function()
		add(buf, true)
	end, "add in editor")
	map("n", "<CR>", function()
		local item = item_at(buf, vim.api.nvim_win_get_cursor(0)[1])
		if item then
			require("rpn.things.editor").edit(item, function()
				refresh_soon(buf)
			end)
		end
	end, "edit")
	map("n", "K", function()
		peek(buf)
	end, "peek notes")
	map("n", "o", function()
		local item = item_at(buf, vim.api.nvim_win_get_cursor(0)[1])
		client.show(item and item.id or states[buf].show_target)
	end, "reveal in Things")
	map("n", "R", function()
		M.refresh(buf)
	end, "refresh")
	map("n", "q", function()
		if vim.fn.buflisted(vim.fn.bufnr("#")) == 1 then
			vim.cmd("buffer #")
		end
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end, "close")
	map("n", "g?", function()
		float(HELP, " Things keys ")
	end, "help")
	for key, view in pairs({
		gi = "inbox",
		gt = "today",
		gu = "upcoming",
		gn = "anytime",
		gs = "someday",
		gl = "logbook",
	}) do
		map("n", key, function()
			M.open(view)
		end, view)
	end
end

local function open_buffer(name, spec)
	local buf = vim.fn.bufnr(name)
	if buf == -1 or not states[buf] then
		define_highlights()
		buf = buf ~= -1 and buf or vim.api.nvim_create_buf(true, true)
		vim.api.nvim_buf_set_name(buf, name)
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "hide"
		vim.bo[buf].swapfile = false
		vim.bo[buf].filetype = "things"
		spec.seq = 0
		states[buf] = spec
		set_keymaps(buf)
		vim.api.nvim_create_autocmd("BufWipeout", {
			buffer = buf,
			once = true,
			callback = function()
				states[buf] = nil
			end,
		})
		-- Things changes outside Neovim too; re-read when coming back to a stale view.
		vim.api.nvim_create_autocmd("BufEnter", {
			buffer = buf,
			callback = function()
				local state = states[buf]
				if state and state.fetched_at and vim.uv.now() - state.fetched_at > 10000 then
					M.refresh(buf)
				end
			end,
		})
		draw(buf)
	end
	vim.api.nvim_set_current_buf(buf)
	M.refresh(buf)
	return buf
end

-- `view` is one of client.VIEWS.
function M.open(view)
	if not TITLES[view] then
		return vim.notify("Unknown Things view: " .. tostring(view), vim.log.levels.ERROR, { title = "Things" })
	end
	return open_buffer("things://" .. view, {
		view = view,
		title = TITLES[view],
		show_target = view,
		add_defaults = ADD_DEFAULTS[view],
		fetch = function(cb)
			client.list(view, cb)
		end,
	})
end

-- `kind` is "project" | "area" (key = id) or "tag" (key = name); `name` labels the buffer.
function M.open_container(kind, key, name)
	local defaults = kind == "tag" and { tags = { key } } or { list_id = key }
	return open_buffer(string.format("things://%s/%s", kind, key), {
		view = kind,
		title = name,
		hide = kind ~= "tag" and kind or nil,
		show_target = kind ~= "tag" and key or nil,
		add_defaults = defaults,
		fetch = function(cb)
			client.container(kind, key, cb)
		end,
	})
end

return M
