-- Turns source lines into a to-do whose notes link back to where they came from.

local client = require("rpn.things.client")
local config = require("rpn.things.config")

local M = {}

local LEADING = { "^%-%-+%s*", "^//+!?%s*", "^#+!?%s*", "^;+%s*", "^/%*+%s*", "^%*+%s*", "^<!%-%-%s*", '^"%s*' }
local TRAILING = { "%s*%*+/$", "%s*%-%->$" }
local MARKERS = { "TODO", "FIXME", "HACK", "XXX", "NOTE", "BUG" }

function M.strip_comment(line)
	local s = vim.trim(line)
	for _, p in ipairs(LEADING) do
		local stripped = s:gsub(p, "", 1)
		if stripped ~= s then
			s = stripped
			break
		end
	end
	for _, p in ipairs(TRAILING) do
		s = s:gsub(p, "")
	end
	for _, m in ipairs(MARKERS) do
		local rest = s:match("^" .. m .. "%b()%s*:?%s*(.*)$")
			or s:match("^" .. m .. "%s*:%s*(.*)$")
			or s:match("^" .. m .. "%s+(.*)$")
		if rest then
			s = rest
			break
		end
	end
	return vim.trim(s)
end

-- Percent-encodes a filesystem path for a file:// URL, keeping `/`.
local function file_url(path)
	return "file://" .. path:gsub("[^%w%-%._~/]", function(c)
		return string.format("%%%02X", c:byte())
	end)
end

-- Pure: `ctx` = { lines, path (display), abs_path, first_line, last_line }.
-- Returns { title, notes } or nil, err.
function M.todo_from(ctx, opts)
	opts = opts or config.values.capture
	local cleaned = vim.tbl_map(function(l)
		return opts.strip_comment_markers and M.strip_comment(l) or vim.trim(l)
	end, ctx.lines)
	local title_index
	for i, l in ipairs(cleaned) do
		if l ~= "" then
			title_index = i
			break
		end
	end
	if not title_index then
		return nil, "nothing to capture"
	end

	local body = vim.list_slice(cleaned, title_index + 1)
	while #body > 0 and body[#body] == "" do
		body[#body] = nil
	end
	local notes = table.concat(body, "\n")
	if opts.backlink and ctx.abs_path and ctx.abs_path ~= "" then
		local range = ctx.first_line == ctx.last_line and tostring(ctx.first_line)
			or string.format("%d-%d", ctx.first_line, ctx.last_line)
		local link = string.format("[%s:%s](%s)", ctx.path, range, file_url(ctx.abs_path))
		notes = notes ~= "" and (notes .. "\n\n" .. link) or link
	end
	return { title = cleaned[title_index], notes = notes }
end

local function display_path(abs)
	local root = vim.fs.root(abs, ".git")
	if root then
		return vim.fs.basename(root) .. "/" .. abs:sub(#root + 2)
	end
	return vim.fn.fnamemodify(abs, ":~:.")
end

-- Captures lines first..last of the current buffer, letting the user edit the title first.
function M.capture(first, last)
	local abs = vim.api.nvim_buf_get_name(0)
	local todo, err = M.todo_from({
		lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false),
		path = abs ~= "" and display_path(abs) or "",
		abs_path = abs,
		first_line = first,
		last_line = last,
	})
	if not todo then
		return vim.notify(err, vim.log.levels.WARN, { title = "Things" })
	end
	vim.ui.input({ prompt = "Things inbox: ", default = todo.title }, function(title)
		if not title or vim.trim(title) == "" then
			return
		end
		todo.title = vim.trim(title)
		client.add(todo, function(add_err)
			if add_err then
				return vim.notify(add_err, vim.log.levels.ERROR, { title = "Things" })
			end
			vim.notify("Added to Inbox: " .. todo.title, vim.log.levels.INFO, { title = "Things" })
		end)
	end)
end

return M
