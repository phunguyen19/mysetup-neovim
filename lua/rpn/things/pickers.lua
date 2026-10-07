local client = require("rpn.things.client")

local M = {}

local function notify_error(err)
	vim.notify(err, vim.log.levels.ERROR, { title = "Things" })
end

local function select(items, prompt, format_item, on_choice)
	vim.ui.select(items, { prompt = prompt, format_item = format_item }, function(choice)
		if choice then
			on_choice(choice)
		end
	end)
end

local function with_area(p)
	return p.area and (p.name .. "  · " .. p.area) or p.name
end

function M.project()
	client.projects(function(err, projects)
		if err then
			return notify_error(err)
		end
		select(projects, "Things project", with_area, function(p)
			require("rpn.things.view").open_container("project", p.id, p.name)
		end)
	end)
end

function M.area()
	client.areas(function(err, areas)
		if err then
			return notify_error(err)
		end
		select(areas, "Things area", function(a)
			return a.name
		end, function(a)
			require("rpn.things.view").open_container("area", a.id, a.name)
		end)
	end)
end

function M.tag()
	client.tags(function(err, tags)
		if err then
			return notify_error(err)
		end
		select(tags, "Things tag", nil, function(tag)
			require("rpn.things.view").open_container("tag", tag, "#" .. tag)
		end)
	end)
end

-- Calls `cb({ id, name })` with a chosen project or area.
function M.destination(cb)
	client.projects(function(err, projects)
		if err then
			return notify_error(err)
		end
		client.areas(function(area_err, areas)
			if area_err then
				return notify_error(area_err)
			end
			local choices = {}
			for _, a in ipairs(areas) do
				choices[#choices + 1] = { id = a.id, name = a.name, label = "▣ " .. a.name }
			end
			for _, p in ipairs(projects) do
				choices[#choices + 1] = { id = p.id, name = p.name, label = "◔ " .. with_area(p) }
			end
			select(choices, "Move to", function(c)
				return c.label
			end, cb)
		end)
	end)
end

local function describe(todo)
	local parts = { todo.title }
	local parent = todo.project or todo.area
	if parent then
		parts[#parts + 1] = "· " .. parent
	end
	for _, tag in ipairs(todo.tags) do
		parts[#parts + 1] = "#" .. tag
	end
	if todo.deadline then
		parts[#parts + 1] = "⚑ " .. todo.deadline
	end
	return table.concat(parts, "  ")
end

-- Fuzzy search over every open to-do. <CR> edit, <C-x> complete, <C-o> reveal in Things.
function M.search()
	vim.notify("Loading Things to-dos…", vim.log.levels.INFO, { title = "Things" })
	client.open_todos(function(err, todos)
		if err then
			return notify_error(err)
		end
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		local editor = require("rpn.things.editor")

		require("telescope.pickers")
			.new({}, {
				prompt_title = "Things to-dos",
				finder = require("telescope.finders").new_table({
					results = todos,
					entry_maker = function(todo)
						local text = describe(todo)
						return { value = todo, display = text, ordinal = text }
					end,
				}),
				sorter = require("telescope.config").values.generic_sorter({}),
				previewer = require("telescope.previewers").new_buffer_previewer({
					title = "To-do",
					define_preview = function(self, entry)
						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, editor.render(entry.value))
						vim.bo[self.state.bufnr].filetype = "markdown"
					end,
				}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						local entry = action_state.get_selected_entry()
						actions.close(prompt_bufnr)
						if entry then
							editor.edit(entry.value)
						end
					end)
					map({ "i", "n" }, "<C-x>", function()
						action_state.get_current_picker(prompt_bufnr):delete_selection(function(entry)
							client.update(entry.value, { completed = true }, function(update_err)
								if update_err then
									return notify_error(update_err)
								end
								vim.notify(
									"Completed: " .. entry.value.title,
									vim.log.levels.INFO,
									{ title = "Things" }
								)
							end)
						end)
					end)
					map({ "i", "n" }, "<C-o>", function()
						local entry = action_state.get_selected_entry()
						if entry then
							client.show(entry.value.id)
						end
					end)
					return true
				end,
			})
			:find()
	end)
end

return M
