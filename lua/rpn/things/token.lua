-- The things:/// auth token, from the macOS Keychain or an env var; cached per session.
-- Never log or display the value.

local config = require("rpn.things.config")

local M = {}

local cached

local function from_env()
	local value = vim.env[config.values.token.env]
	if value and vim.trim(value) ~= "" then
		return vim.trim(value)
	end
end

-- Calls `cb(token)` or `cb(nil, err)` on the main loop.
function M.get(cb)
	if cached then
		return cb(cached)
	end
	local service = config.values.token.keychain_service
	vim.system({ "security", "find-generic-password", "-s", service, "-w" }, { text = true }, function(res)
		vim.schedule(function()
			local value = res.code == 0 and vim.trim(res.stdout or "") or ""
			cached = value ~= "" and value or from_env()
			if cached then
				return cb(cached)
			end
			cb(
				nil,
				string.format(
					"Things auth token not found (Keychain service %q or $%s). See :ThingsTokenCheck",
					service,
					config.values.token.env
				)
			)
		end)
	end)
end

function M.clear()
	cached = nil
end

return M
