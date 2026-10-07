-- The to-do shape every other module works with, built from read.js output.

local M = {}

M.WHEN = { "today", "evening", "tomorrow", "anytime", "someday" }

local function split_tags(s)
	local tags = {}
	for tag in (s or ""):gmatch("[^,]+") do
		tag = vim.trim(tag)
		if tag ~= "" then
			tags[#tags + 1] = tag
		end
	end
	return tags
end

function M.todo(raw)
	return {
		id = raw.id,
		kind = raw.kind or "todo",
		title = raw.name or "",
		notes = raw.notes or "",
		status = raw.status or "open",
		when = raw.when,
		deadline = raw.deadline,
		completed_on = raw.completed,
		tags = split_tags(raw.tags),
		project = raw.project,
		project_id = raw.projectId,
		area = raw.area,
		area_id = raw.areaId,
	}
end

function M.todos(raws)
	return vim.tbl_map(M.todo, raws)
end

function M.today()
	return os.date("%Y-%m-%d")
end

-- Dates are YYYY-MM-DD, so string order is chronological order.
function M.is_overdue(todo, today)
	return todo.status == "open" and todo.deadline ~= nil and todo.deadline < (today or M.today())
end

function M.short_date(ymd, today)
	local y, m, d = (ymd or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	if not y then
		return ymd
	end
	local label = os.date("%b %d", os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }))
	if y ~= (today or M.today()):sub(1, 4) then
		label = label .. " " .. y
	end
	return label
end

-- The URL-scheme changes that move a to-do between statuses; nil when nothing changes.
function M.status_changes(from, to)
	if from == to then
		return nil
	end
	if to == "completed" then
		return { completed = true }
	elseif to == "canceled" then
		return { canceled = true }
	elseif from == "canceled" then
		return { canceled = false }
	end
	return { completed = false }
end

return M
