local M = {}

M.defaults = {
	keymap_prefix = "<leader>T",
	-- things:/// is fire-and-forget; give Things time to apply a write before re-reading
	refresh_delay_ms = 400,
	logbook_limit = 50,
	token = { keychain_service = "things3-nvim", env = "THINGS_AUTH_TOKEN" },
	capture = { strip_comment_markers = true, backlink = true },
}

M.values = vim.deepcopy(M.defaults)

function M.set(opts)
	M.values = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
