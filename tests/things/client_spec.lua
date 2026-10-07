local client = require("rpn.things.client")
local config = require("rpn.things.config")
local token = require("rpn.things.token")

local function await(fn)
	local result
	fn(function(...)
		result = { ... }
	end)
	vim.wait(2000, function()
		return result ~= nil
	end)
	assert.is_not_nil(result, "callback never fired")
	return unpack(result, 1, 2)
end

-- Records every vim.system call; `respond(argv, opts)` returns { code, stdout, stderr }.
local function stub_system(respond)
	local calls = {}
	local original = vim.system
	vim.system = function(argv, opts, on_exit)
		calls[#calls + 1] = { argv = argv, opts = opts }
		local res = respond(argv, opts)
		vim.schedule(function()
			on_exit(res)
		end)
	end
	return calls, function()
		vim.system = original
	end
end

local function respond_with(read_result)
	return function(argv)
		if argv[1] == "security" then
			return { code = 44, stdout = "", stderr = "not found" }
		end
		if argv[4]:match("open%.js$") then
			return { code = 0, stdout = "ok", stderr = "" }
		end
		return read_result or { code = 0, stdout = "[]", stderr = "" }
	end
end

describe("client", function()
	local calls, restore

	before_each(function()
		config.set({ token = { keychain_service = "rpn-things-test", env = "RPN_THINGS_TEST_TOKEN" } })
		vim.env.RPN_THINGS_TEST_TOKEN = "s3cr3t-token"
		token.clear()
	end)

	after_each(function()
		if restore then
			restore()
		end
		vim.env.RPN_THINGS_TEST_TOKEN = nil
		token.clear()
	end)

	it("adds through open.js without a token", function()
		calls, restore = stub_system(respond_with())
		local err = await(function(cb)
			client.add({ title = "Buy milk" }, cb)
		end)
		assert.is_nil(err)
		assert.equals(1, #calls)
		assert.matches("open%.js$", calls[1].argv[4])
		assert.equals("things:///add?title=Buy%20milk", calls[1].opts.stdin)
	end)

	it("passes the token on stdin, never in argv", function()
		calls, restore = stub_system(respond_with())
		local err = await(function(cb)
			client.update({ id = "A1" }, { completed = true }, cb)
		end)
		assert.is_nil(err)
		local open_call = calls[#calls]
		assert.matches("auth%-token=s3cr3t%-token", open_call.opts.stdin)
		for _, call in ipairs(calls) do
			for _, arg in ipairs(call.argv) do
				assert.is_nil(arg:find("s3cr3t", 1, true))
			end
		end
	end)

	it("updates projects through update-project", function()
		calls, restore = stub_system(respond_with())
		assert.is_nil((await(function(cb)
			client.update({ id = "P1", kind = "project" }, { title = "x" }, cb)
		end)))
		assert.matches("^things:///update%-project%?", calls[#calls].opts.stdin)
	end)

	it("redacts the token from write errors", function()
		calls, restore = stub_system(function(argv)
			if argv[1] == "security" then
				return { code = 44, stdout = "", stderr = "" }
			end
			return {
				code = 1,
				stdout = "",
				stderr = "failed to open things:///update?auth-token=s3cr3t-token&id=A1 (s3cr3t-token)",
			}
		end)
		local err = await(function(cb)
			client.update({ id = "A1" }, { completed = true }, cb)
		end)
		assert.is_nil(err:find("s3cr3t", 1, true))
		assert.matches("REDACTED", err)
	end)

	it("fails updates without a token and never opens a URL", function()
		vim.env.RPN_THINGS_TEST_TOKEN = nil
		calls, restore = stub_system(respond_with())
		local err = await(function(cb)
			client.update({ id = "A1" }, { completed = true }, cb)
		end)
		assert.matches("token not found", err)
		assert.equals(1, #calls)
		assert.equals("security", calls[1].argv[1])
	end)

	it("reads a list and decodes nulls to nil", function()
		calls, restore = stub_system(respond_with({
			code = 0,
			stdout = '[{"id":"A1","name":"T","status":"open","notes":"","tags":"x","deadline":null,"when":null,"completed":null,"projectId":null,"project":null,"areaId":null,"area":null}]',
			stderr = "",
		}))
		local err, todos = await(function(cb)
			client.list("today", cb)
		end)
		assert.is_nil(err)
		assert.same({ "list", "TMTodayListSource" }, vim.list_slice(calls[1].argv, 5))
		assert.equals("T", todos[1].title)
		assert.is_nil(todos[1].deadline)
		assert.same({ "x" }, todos[1].tags)
	end)

	it("reports read failures and garbage output", function()
		calls, restore = stub_system(respond_with({ code = 1, stdout = "", stderr = "Things got an error" }))
		local err = await(function(cb)
			client.list("inbox", cb)
		end)
		assert.matches("Things read failed: Things got an error", err)
		restore()

		calls, restore = stub_system(respond_with({ code = 0, stdout = "not json", stderr = "" }))
		err = await(function(cb)
			client.list("inbox", cb)
		end)
		assert.equals("Things returned unreadable data", err)
	end)

	it("rejects unknown views and invalid ids before running anything", function()
		calls, restore = stub_system(respond_with())
		assert.matches("unknown Things view", (await(function(cb)
			client.list("trash", cb)
		end)))
		assert.matches("invalid project id", (await(function(cb)
			client.container("project", "a b", cb)
		end)))
		assert.equals(0, #calls)
	end)
end)
