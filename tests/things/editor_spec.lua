local editor = require("rpn.things.editor")

local todo = {
	id = "A1",
	title = "Review PR",
	when = "2026-10-05",
	deadline = nil,
	tags = { "work" },
	notes = "line 1\nline 2",
}

describe("editor", function()
	it("round-trips render -> parse", function()
		assert.same({
			title = "Review PR",
			when = "2026-10-05",
			deadline = "",
			tags = { "work" },
			checklist = {},
			notes = "line 1\nline 2",
		}, editor.parse(editor.render(todo)))
	end)

	it("diffs only the fields that changed", function()
		local lines = editor.render(todo)
		local before = editor.parse(lines)
		lines[1] = "Review PR #42"
		lines[3] = "deadline: 2026-10-10"
		table.insert(lines, 5, "- [ ] run tests")
		assert.same({
			title = "Review PR #42",
			deadline = "2026-10-10",
			append_checklist_items = { "run tests" },
		}, editor.diff(before, editor.parse(lines)))
	end)

	it("reports no changes for an untouched buffer", function()
		local before = editor.parse(editor.render(todo))
		assert.same({}, editor.diff(before, editor.parse(editor.render(todo))))
	end)

	it("treats a cleared when as anytime and cleared tags as none", function()
		local lines = editor.render(todo)
		local before = editor.parse(lines)
		lines[2] = "when:"
		lines[4] = "tags:"
		assert.same({ when = "anytime", tags = {} }, editor.diff(before, editor.parse(lines)))
	end)

	it("keeps '---' inside notes", function()
		local fields = editor.parse({ "T", "---", "a", "---", "b", "", "" })
		assert.equals("a\n---\nb", fields.notes)
	end)

	it("rejects malformed buffers", function()
		assert.is_nil(editor.parse({ "T", "when: today" }))
		assert.is_nil(editor.parse({ "", "---" }))
		local _, err = editor.parse({ "T", "nonsense", "---" })
		assert.matches("line 2", err)
	end)

	it("builds an add payload on top of view defaults", function()
		local fields = editor.parse({ "New", "when: tomorrow", "deadline:", "tags: a", "- [ ] one", "---", "" })
		assert.same(
			{ title = "New", when = "tomorrow", tags = { "a" }, checklist_items = { "one" }, list_id = "PRJ1" },
			editor.to_new(fields, { list_id = "PRJ1" })
		)
	end)
end)
