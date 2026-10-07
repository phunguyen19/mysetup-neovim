-- Builds things:/// URLs (https://culturedcode.com/things/support/articles/2803573/).
-- Fields use Lua names (`list_id`) and Lua values (tags as a list, booleans);
-- every builder returns `url` or `nil, err`.

local M = {}

local KINDS = {
	title = "text",
	notes = "text",
	prepend_notes = "text",
	append_notes = "text",
	when = "date",
	deadline = "date",
	tags = "tags",
	add_tags = "tags",
	checklist_items = "lines",
	prepend_checklist_items = "lines",
	append_checklist_items = "lines",
	to_dos = "lines",
	list = "text",
	list_id = "id",
	heading = "text",
	heading_id = "id",
	area = "text",
	area_id = "id",
	completed = "bool",
	canceled = "bool",
	reveal = "bool",
}

local function set(...)
	local s = {}
	for _, k in ipairs({ ... }) do
		s[k] = true
	end
	return s
end

local ALLOWED = {
	add = set(
		"title",
		"notes",
		"when",
		"deadline",
		"tags",
		"checklist_items",
		"list",
		"list_id",
		"heading",
		"heading_id",
		"completed",
		"canceled",
		"reveal"
	),
	["add-project"] = set(
		"title",
		"notes",
		"when",
		"deadline",
		"tags",
		"area",
		"area_id",
		"to_dos",
		"completed",
		"canceled",
		"reveal"
	),
	update = set(
		"title",
		"notes",
		"prepend_notes",
		"append_notes",
		"when",
		"deadline",
		"tags",
		"add_tags",
		"checklist_items",
		"prepend_checklist_items",
		"append_checklist_items",
		"list",
		"list_id",
		"heading",
		"heading_id",
		"completed",
		"canceled",
		"reveal"
	),
	["update-project"] = set(
		"title",
		"notes",
		"prepend_notes",
		"append_notes",
		"when",
		"deadline",
		"tags",
		"add_tags",
		"area",
		"area_id",
		"completed",
		"canceled",
		"reveal"
	),
}

-- Things truncates silently past these; failing loudly is better than losing text.
local MAX_LEN = { title = 4000, notes = 10000, prepend_notes = 10000, append_notes = 10000 }

local function is_id(s)
	return type(s) == "string" and s:match("^[%w%-]+$") ~= nil
end

-- RFC 3986 unreserved characters pass through; Things requires %20, never `+`.
function M.encode(s)
	return (tostring(s):gsub("[^%w%-%._~]", function(c)
		return string.format("%%%02X", c:byte())
	end))
end

local function check_line(field, s)
	if type(s) ~= "string" then
		return nil, field .. " must be a string"
	end
	if s:find("[%c]") then
		return nil, field .. " must be a single line"
	end
	return s
end

-- Returns the field normalised for the URL scheme (strings) and for JSON (raw lists).
local function check(field, value)
	local kind = KINDS[field]
	if kind == "text" then
		if type(value) ~= "string" then
			return nil, field .. " must be a string"
		end
		if MAX_LEN[field] and #value > MAX_LEN[field] then
			return nil, string.format("%s exceeds %d characters", field, MAX_LEN[field])
		end
		return value
	elseif kind == "date" then
		return check_line(field, value)
	elseif kind == "id" then
		if not is_id(value) then
			return nil, "invalid " .. field
		end
		return value
	elseif kind == "bool" then
		if type(value) ~= "boolean" then
			return nil, field .. " must be a boolean"
		end
		return value
	elseif kind == "tags" or kind == "lines" then
		if type(value) ~= "table" then
			return nil, field .. " must be a list"
		end
		for _, item in ipairs(value) do
			local _, err = check_line(field, item)
			if err then
				return nil, err
			end
			if kind == "tags" and item:find(",", 1, true) then
				return nil, "tag names cannot contain commas"
			end
		end
		return value
	end
	return nil, "unknown field " .. tostring(field)
end

local function as_param(field, value)
	local kind = KINDS[field]
	if kind == "tags" then
		return table.concat(value, ",")
	elseif kind == "lines" then
		return table.concat(value, "\n")
	end
	return tostring(value)
end

local function validated(command, fields)
	local out = {}
	for field, value in pairs(fields or {}) do
		if not ALLOWED[command][field] then
			return nil, string.format("%s does not accept %s", command, field)
		end
		local v, err = check(field, value)
		if err then
			return nil, err
		end
		out[field] = v
	end
	return out
end

-- `pairs` order is random; sorting keeps URLs deterministic for tests and logs.
local function build(command, params)
	local keys = vim.tbl_keys(params)
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do
		parts[#parts + 1] = M.encode(k) .. "=" .. M.encode(params[k])
	end
	return "things:///" .. command .. (#parts > 0 and ("?" .. table.concat(parts, "&")) or "")
end

local function to_params(fields)
	local params = {}
	for field, value in pairs(fields) do
		params[(field:gsub("_", "-"))] = as_param(field, value)
	end
	return params
end

local function create(command, fields)
	local valid, err = validated(command, fields)
	if not valid then
		return nil, err
	end
	if not valid.title or valid.title == "" then
		return nil, "title is required"
	end
	return build(command, to_params(valid))
end

local function modify(command, id, changes, token)
	if not is_id(id) then
		return nil, "invalid id"
	end
	if type(token) ~= "string" or token == "" then
		return nil, "auth token required"
	end
	local valid, err = validated(command, changes)
	if not valid then
		return nil, err
	end
	if next(valid) == nil then
		return nil, "nothing to update"
	end
	if valid.title == "" then
		return nil, "title cannot be empty"
	end
	local params = to_params(valid)
	params.id = id
	params["auth-token"] = token
	return build(command, params)
end

function M.add(todo)
	return create("add", todo)
end

function M.add_project(project)
	return create("add-project", project)
end

function M.update(id, changes, token)
	return modify("update", id, changes, token)
end

function M.update_project(id, changes, token)
	return modify("update-project", id, changes, token)
end

-- One things:///json call; `updates` is a list of { id, kind = "todo"|"project", changes }.
function M.update_many(updates, token)
	if type(token) ~= "string" or token == "" then
		return nil, "auth token required"
	end
	if #updates == 0 then
		return nil, "nothing to update"
	end
	local ops = {}
	for _, u in ipairs(updates) do
		if not is_id(u.id) then
			return nil, "invalid id"
		end
		local is_project = u.kind == "project"
		local valid, err = validated(is_project and "update-project" or "update", u.changes)
		if not valid then
			return nil, err
		end
		if next(valid) == nil then
			return nil, "nothing to update"
		end
		local attributes = {}
		for field, value in pairs(valid) do
			if KINDS[field] == "lines" then
				value = vim.tbl_map(function(title)
					return { type = "checklist-item", attributes = { title = title } }
				end, value)
			end
			attributes[(field:gsub("_", "-"))] = value
		end
		ops[#ops + 1] =
			{ type = is_project and "project" or "to-do", operation = "update", id = u.id, attributes = attributes }
	end
	return build("json", { data = vim.json.encode(ops), ["auth-token"] = token })
end

-- `target` is an item ID or a built-in list ("today", "inbox", ...).
function M.show(target)
	if not is_id(target) then
		return nil, "invalid show target"
	end
	return build("show", { id = target })
end

return M
