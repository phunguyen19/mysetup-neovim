local url = require("rpn.things.url")

local function params(u)
	local out = {}
	for k, v in (u:match("%?(.*)$") or ""):gmatch("([^&=]+)=([^&]*)") do
		out[k] = v:gsub("%%(%x%x)", function(h)
			return string.char(tonumber(h, 16))
		end)
	end
	return out
end

describe("url.encode", function()
	it("uses %20 for spaces and encodes reserved and non-ASCII bytes", function()
		assert.equals("a%20b%26c%3Dd%2Fe%C3%A9-_.~", url.encode("a b&c=d/eé-_.~"))
	end)

	it("encodes newlines", function()
		assert.equals("x%0Ay", url.encode("x\ny"))
	end)
end)

describe("url.add", function()
	it("builds a deterministic add URL", function()
		local u = url.add({ title = "Buy milk", when = "today", tags = { "errand", "home" } })
		assert.equals("things:///add?tags=errand%2Chome&title=Buy%20milk&when=today", u)
	end)

	it("joins checklist items with newlines and maps list_id", function()
		local p = params(assert(url.add({ title = "t", checklist_items = { "a", "b" }, list_id = "PRJ1" })))
		assert.equals("a\nb", p["checklist-items"])
		assert.equals("PRJ1", p["list-id"])
	end)

	it("keeps injected separators inside the value", function()
		local p = params(assert(url.add({ title = "x&auth-token=evil&completed=true" })))
		assert.equals("x&auth-token=evil&completed=true", p.title)
		assert.is_nil(p.completed)
	end)

	it("never carries an auth token", function()
		assert.is_nil(url.add({ title = "t" }):find("auth%-token"))
	end)

	it("requires a title", function()
		local u, err = url.add({ notes = "n" })
		assert.is_nil(u)
		assert.equals("title is required", err)
	end)

	it("rejects fields the command does not accept", function()
		local _, err = url.add({ title = "t", add_tags = { "x" } })
		assert.matches("does not accept add_tags", err)
	end)

	it("rejects wrongly typed and malformed values", function()
		assert.is_nil(url.add({ title = "t", completed = "yes" }))
		assert.is_nil(url.add({ title = "t", tags = { "a,b" } }))
		assert.is_nil(url.add({ title = "t", when = "today\n&x=1" }))
		assert.is_nil(url.add({ title = "t", list_id = "../etc" }))
		assert.is_nil(url.add({ title = "t", notes = string.rep("n", 10001) }))
	end)
end)

describe("url.update", function()
	it("adds id and auth token", function()
		assert.equals(
			"things:///update?auth-token=tok&completed=true&id=ABC123",
			url.update("ABC123", { completed = true }, "tok")
		)
	end)

	it("allows clearing a deadline", function()
		assert.equals("", params(assert(url.update("A1", { deadline = "" }, "tok"))).deadline)
	end)

	it("requires a token, a valid id and at least one change", function()
		assert.is_nil(url.update("A1", { completed = true }, nil))
		assert.is_nil(url.update("A1", { completed = true }, ""))
		assert.is_nil(url.update("A1&x=1", { completed = true }, "tok"))
		local _, err = url.update("A1", {}, "tok")
		assert.equals("nothing to update", err)
	end)

	it("refuses to blank a title", function()
		assert.is_nil(url.update("A1", { title = "" }, "tok"))
	end)

	it("uses update-project for projects", function()
		assert.matches("^things:///update%-project%?", url.update_project("P1", { title = "x" }, "tok"))
	end)
end)

describe("url.update_many", function()
	it("encodes one json update operation per to-do", function()
		local u = assert(url.update_many({
			{ id = "A1", changes = { completed = true } },
			{ id = "B2", changes = { tags = { "x" }, append_checklist_items = { "c" } } },
		}, "tok"))
		assert.matches("^things:///json%?", u)
		local p = params(u)
		assert.equals("tok", p["auth-token"])
		local ops = vim.json.decode(p.data)
		assert.same({ type = "to-do", operation = "update", id = "A1", attributes = { completed = true } }, ops[1])
		assert.same({ "x" }, ops[2].attributes.tags)
		assert.same(
			{ { type = "checklist-item", attributes = { title = "c" } } },
			ops[2].attributes["append-checklist-items"]
		)
	end)

	it("updates projects as projects and applies project rules", function()
		local p =
			params(assert(url.update_many({ { id = "P1", kind = "project", changes = { completed = true } } }, "tok")))
		assert.equals("project", vim.json.decode(p.data)[1].type)
		assert.is_nil(
			url.update_many({ { id = "P1", kind = "project", changes = { append_checklist_items = { "x" } } } }, "tok")
		)
	end)

	it("rejects an invalid id anywhere in the batch", function()
		assert.is_nil(
			url.update_many(
				{ { id = "A1", changes = { completed = true } }, { id = "x y", changes = { completed = true } } },
				"tok"
			)
		)
	end)
end)

describe("url.show", function()
	it("shows lists and items", function()
		assert.equals("things:///show?id=today", url.show("today"))
		assert.equals("things:///show?id=AAA111", url.show("AAA111"))
		assert.is_nil(url.show("a b"))
	end)
end)
