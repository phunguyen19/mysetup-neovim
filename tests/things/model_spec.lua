local model = require("rpn.things.model")

local function fixture()
	local path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/fixtures/today.json"
	return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"), { luanil = { object = true, array = true } })
end

describe("model.todos", function()
	it("normalizes read.js output", function()
		local todos = model.todos(fixture())
		assert.same({
			id = "AAA111",
			kind = "todo",
			title = "Review settlement PR",
			notes = "check idempotency",
			status = "open",
			when = "2026-10-05",
			deadline = "2026-10-04",
			tags = { "work", "payments" },
			project = "Payments",
			project_id = "PRJ1",
			area = "Work",
			area_id = "AR1",
		}, todos[1])
		assert.same({}, todos[2].tags)
		assert.equals("2026-10-05", todos[2].completed_on)
		assert.is_nil(todos[2].project)
	end)
end)

describe("model dates", function()
	it("flags open to-dos past their deadline", function()
		assert.is_true(model.is_overdue({ status = "open", deadline = "2026-10-04" }, "2026-10-05"))
		assert.is_false(model.is_overdue({ status = "open", deadline = "2026-10-05" }, "2026-10-05"))
		assert.is_false(model.is_overdue({ status = "completed", deadline = "2026-10-01" }, "2026-10-05"))
		assert.is_false(model.is_overdue({ status = "open" }, "2026-10-05"))
	end)

	it("formats short dates, adding the year only when it differs", function()
		assert.equals("Oct 07", model.short_date("2026-10-07", "2026-10-05"))
		assert.equals("Jan 02 2027", model.short_date("2027-01-02", "2026-10-05"))
	end)
end)

describe("model.status_changes", function()
	it("maps status transitions to URL fields", function()
		assert.same({ completed = true }, model.status_changes("open", "completed"))
		assert.same({ canceled = true }, model.status_changes("open", "canceled"))
		assert.same({ completed = false }, model.status_changes("completed", "open"))
		assert.same({ canceled = false }, model.status_changes("canceled", "open"))
		assert.is_nil(model.status_changes("open", "open"))
	end)
end)
