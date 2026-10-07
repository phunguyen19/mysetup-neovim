local model = require("rpn.things.model")
local view = require("rpn.things.view")

local function fixture()
	local path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/fixtures/today.json"
	return model.todos(
		vim.json.decode(table.concat(vim.fn.readfile(path), "\n"), { luanil = { object = true, array = true } })
	)
end

local function virt_text(out, line)
	for _, m in ipairs(out.marks) do
		if m.virt_text and m.line == line then
			return table.concat(vim.tbl_map(function(c)
				return c[1]
			end, m.virt_text))
		end
	end
	return ""
end

local function has_hl(out, line, hl)
	for _, m in ipairs(out.marks) do
		if m.line == line and m.hl == hl then
			return true
		end
	end
	return false
end

describe("view.render", function()
	it("renders a header and one line per to-do mapped to its item", function()
		local todos = fixture()
		local out = view.render("Today", todos, { today = "2026-10-05" })
		assert.same({ "Today · 2", "", "  [ ] Review settlement PR", "  (x) Rotate API keys" }, out.lines)
		assert.equals("AAA111", out.items[3].id)
		assert.equals("BBB222", out.items[4].id)
		assert.is_nil(out.items[1])
	end)

	it("shows tags, overdue deadline, notes marker and project as virtual text", function()
		local out = view.render("Today", fixture(), { today = "2026-10-05" })
		assert.equals("  #work  #payments  ⚑ Oct 04  ✎  Payments", virt_text(out, 2))
	end)

	it("highlights overdue deadlines", function()
		local function deadline_hl(today)
			for _, m in ipairs(view.render("Today", fixture(), { today = today }).marks) do
				for _, chunk in ipairs(m.line == 2 and m.virt_text or {}) do
					if chunk[1]:find("⚑", 1, true) then
						return chunk[2]
					end
				end
			end
		end
		assert.equals("ThingsOverdue", deadline_hl("2026-10-05"))
		assert.equals("ThingsDeadline", deadline_hl("2026-10-01"))
	end)

	it("strikes through finished to-dos", function()
		local out = view.render("Today", fixture(), { today = "2026-10-05" })
		assert.is_true(has_hl(out, 3, "ThingsStrike"))
		assert.is_false(has_hl(out, 2, "ThingsStrike"))
	end)

	it("hides the project column inside a project view", function()
		local out = view.render("Payments", fixture(), { today = "2026-10-05", hide = "project" })
		assert.is_nil(virt_text(out, 2):find("Payments", 1, true))
		assert.is_nil(virt_text(out, 3):find("Work", 1, true))
	end)

	it("falls back to the area when there is no project", function()
		local out = view.render("Today", fixture(), { today = "2026-10-05" })
		assert.matches("Work", virt_text(out, 3))
	end)

	it("marks pending writes and the loading state", function()
		local todos = fixture()
		todos[1].pending = true
		assert.matches("%(syncing%)", virt_text(view.render("Today", todos, { today = "2026-10-05" }), 2))
		assert.equals("Today · loading…", view.render("Today", {}, { loading = true }).lines[1])
		assert.equals("  (empty)", view.render("Today", {}, {}).lines[3])
	end)

	it("completes the last comma-separated tag", function()
		local names = { "work", "Waiting", "home" }
		assert.same({ "work", "Waiting" }, view.tag_completions("w", names))
		assert.same({ "home, work", "home, Waiting" }, view.tag_completions("home, W", names))
		assert.same(names, view.tag_completions("", names))
	end)
end)
