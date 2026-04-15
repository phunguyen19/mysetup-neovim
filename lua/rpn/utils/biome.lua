local M = {}

function M.is_biome_project(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local cached = vim.b[bufnr].rpn_biome_project
	if cached ~= nil then
		return cached
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	local search_path = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
	local found = vim.fs.find({ "biome.json", "biome.jsonc" }, {
		upward = true,
		path = search_path,
		type = "file",
	})

	local result = #found > 0
	vim.b[bufnr].rpn_biome_project = result
	return result
end

return M
