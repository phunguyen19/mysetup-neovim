local capture = require("rpn.things.capture")

describe("capture.strip_comment", function()
	local cases = {
		["  -- TODO: fix lua thing"] = "fix lua thing",
		["// FIXME(rpn): handle nil"] = "handle nil",
		["# TODO handle retries"] = "handle retries",
		["/* HACK: temporary */"] = "temporary",
		["<!-- NOTE: docs -->"] = "docs",
		["local x = 1"] = "local x = 1",
		["// TODOS are fine"] = "TODOS are fine",
	}
	for input, expected in pairs(cases) do
		it(string.format("%q", input), function()
			assert.equals(expected, capture.strip_comment(input))
		end)
	end
end)

describe("capture.todo_from", function()
	local opts = { strip_comment_markers = true, backlink = true }

	it("uses the first non-empty line as title and links back to the source", function()
		local todo = capture.todo_from({
			lines = { "", "// TODO: retry on 429", "// use exponential backoff", "" },
			path = "app/src/http client.ts",
			abs_path = "/repo/src/http client.ts",
			first_line = 10,
			last_line = 13,
		}, opts)
		assert.same({
			title = "retry on 429",
			notes = "use exponential backoff\n\n[app/src/http client.ts:10-13](file:///repo/src/http%20client.ts)",
		}, todo)
	end)

	it("links a single line without a range", function()
		local todo = capture.todo_from(
			{ lines = { "fix me" }, path = "a.lua", abs_path = "/a.lua", first_line = 3, last_line = 3 },
			opts
		)
		assert.equals("[a.lua:3](file:///a.lua)", todo.notes)
	end)

	it("skips the backlink when disabled or the buffer has no file", function()
		local ctx = { lines = { "x" }, path = "", abs_path = "", first_line = 1, last_line = 1 }
		assert.equals("", capture.todo_from(ctx, opts).notes)
		ctx.abs_path = "/a.lua"
		assert.equals("", capture.todo_from(ctx, { strip_comment_markers = true, backlink = false }).notes)
	end)

	it("refuses blank selections", function()
		assert.is_nil(capture.todo_from({ lines = { "", "  //  " }, first_line = 1, last_line = 2 }, opts))
	end)
end)
