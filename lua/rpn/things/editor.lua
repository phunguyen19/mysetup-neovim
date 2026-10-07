-- Float editor for one to-do. `:w` sends only the fields that changed.
--
--   Title
--   when: 2026-10-07
--   deadline:
--   tags: work, payments
--   - [ ] new checklist item      (appended; Things' AppleScript can't read checklists)
--   ---
--   notes…

local client = require("rpn.things.client")

local M = {}

local SEPARATOR = "---"
local HEADER_KEYS = { when = true, deadline = true, tags = true }

function M.render(todo)
	local lines = {
		todo.title or "",
		"when: " .. (todo.when or ""),
		"deadline: " .. (todo.deadline or ""),
		"tags: " .. table.concat(todo.tags or {}, ", "),
		SEPARATOR,
	}
	vim.list_extend(lines, vim.split(todo.notes or "", "\n"))
	return lines
end

local function split_tags(s)
	local tags = {}
	for tag in s:gmatch("[^,]+") do
		if vim.trim(tag) ~= "" then
			tags[#tags + 1] = vim.trim(tag)
		end
	end
	return tags
end

-- Returns { title, when, deadline, tags, checklist, notes } or nil, err.
function M.parse(lines)
	local sep
	for i, line in ipairs(lines) do
		if line == SEPARATOR then
			sep = i
			break
		end
	end
	if not sep then
		return nil, "missing '---' line between header and notes"
	end

	local fields = { title = vim.trim(lines[1] or ""), when = "", deadline = "", tags = {}, checklist = {} }
	if sep == 1 or fields.title == "" then
		return nil, "the first line must be the title"
	end
	for i = 2, sep - 1 do
		local line = lines[i]
		local key, value = line:match("^(%a+):%s*(.-)%s*$")
		local item = line:match("^%s*%- %[ %]%s+(.-)%s*$")
		if key and HEADER_KEYS[key] then
			fields[key] = key == "tags" and split_tags(value) or value
		elseif item and item ~= "" then
			fields.checklist[#fields.checklist + 1] = item
		elseif vim.trim(line) ~= "" then
			return nil, string.format("line %d: expected when:/deadline:/tags: or '- [ ] item'", i)
		end
	end

	local notes = vim.list_slice(lines, sep + 1)
	while #notes > 0 and vim.trim(notes[#notes]) == "" do
		notes[#notes] = nil
	end
	fields.notes = table.concat(notes, "\n")
	return fields
end

-- The update changes that turn `before` into `after` (both from `parse`).
function M.diff(before, after)
	local changes = {}
	if after.title ~= before.title then
		changes.title = after.title
	end
	if after.notes ~= before.notes then
		changes.notes = after.notes
	end
	if after.when ~= before.when then
		-- A cleared date means "no date", which Things calls anytime.
		changes.when = after.when ~= "" and after.when or "anytime"
	end
	if after.deadline ~= before.deadline then
		changes.deadline = after.deadline
	end
	if table.concat(after.tags, ",") ~= table.concat(before.tags, ",") then
		changes.tags = after.tags
	end
	if #after.checklist > 0 then
		changes.append_checklist_items = after.checklist
	end
	return changes
end

-- The add fields for a new to-do; `defaults` carries what the editor doesn't show (list_id).
function M.to_new(fields, defaults)
	local todo = vim.deepcopy(defaults or {})
	todo.title = fields.title
	todo.notes = fields.notes ~= "" and fields.notes or nil
	todo.when = fields.when ~= "" and fields.when or nil
	todo.deadline = fields.deadline ~= "" and fields.deadline or nil
	todo.tags = #fields.tags > 0 and fields.tags or nil
	todo.checklist_items = #fields.checklist > 0 and fields.checklist or nil
	return todo
end

local function open_float(name, lines, title, on_write)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, name)
	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].modified = false

	local width = math.min(90, math.floor(vim.o.columns * 0.7))
	local height = math.max(12, math.floor(vim.o.lines * 0.5))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		border = "rounded",
		title = title,
		footer = " :w save · q discard ",
		footer_pos = "right",
	})
	vim.wo[win].wrap = true

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, desc = "Things: discard" })
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			local fields, err = M.parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
			if not fields then
				return vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
			end
			on_write(fields, function(write_err)
				if write_err then
					return vim.notify(write_err, vim.log.levels.ERROR, { title = "Things" })
				end
				if vim.api.nvim_buf_is_valid(buf) then
					vim.bo[buf].modified = false
				end
				close()
			end)
		end,
	})
end

function M.edit(todo, on_save)
	local lines = M.render(todo)
	local before = M.parse(lines)
	if not before then
		return vim.notify(
			"To-dos without a title can only be edited in Things",
			vim.log.levels.WARN,
			{ title = "Things" }
		)
	end
	open_float("things://edit/" .. todo.id, lines, " Edit to-do ", function(after, done)
		local changes = M.diff(before, after)
		if next(changes) == nil then
			return done()
		end
		client.update(todo, changes, function(err)
			done(err)
			if not err and on_save then
				on_save()
			end
		end)
	end)
end

function M.create(defaults, on_save)
	defaults = defaults or {}
	local lines = M.render({ title = "", when = defaults.when, tags = defaults.tags })
	open_float("things://new/" .. vim.uv.hrtime(), lines, " New to-do ", function(fields, done)
		client.add(M.to_new(fields, defaults), function(err)
			done(err)
			if not err and on_save then
				on_save()
			end
		end)
	end)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	vim.cmd("startinsert")
end

return M
