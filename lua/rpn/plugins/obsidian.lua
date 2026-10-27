-- vaults are per machine: set obsidian_vaults in lua/rpn/local.lua (see local.example.lua)
local ok, machine = pcall(require, "rpn.local")
local vaults = (ok and type(machine) == "table" and machine.obsidian_vaults) or {}

-- load only for markdown files inside a vault (or via the keymaps below)
local vault_patterns = {}
for _, v in ipairs(vaults) do
	table.insert(vault_patterns, vim.fn.expand(v.path) .. "/*.md")
end

return {
	"epwalsh/obsidian.nvim",
	version = "*",
	enabled = #vaults > 0,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
		"nvim-telescope/telescope.nvim",
	},
	event = {
		"BufReadPre " .. table.concat(vault_patterns, ","),
		"BufNewFile " .. table.concat(vault_patterns, ","),
	},
	cmd = { "ObsidianQuickSwitch", "ObsidianSearch", "ObsidianNew", "ObsidianToday", "ObsidianWorkspace" },
	keys = {
		{ "<leader>Of", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: find note" },
		{ "<leader>Os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: grep vault" },
		{ "<leader>On", "<cmd>ObsidianNew<cr>", desc = "Obsidian: new note" },
		{ "<leader>Ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian: today's daily note" },
		{ "<leader>Oy", "<cmd>ObsidianYesterday<cr>", desc = "Obsidian: yesterday's daily note" },
		{ "<leader>Ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: backlinks" },
		{ "<leader>Ol", "<cmd>ObsidianLinks<cr>", desc = "Obsidian: links in note" },
		{ "<leader>Og", "<cmd>ObsidianTags<cr>", desc = "Obsidian: tags" },
		{ "<leader>Ow", "<cmd>ObsidianWorkspace<cr>", desc = "Obsidian: switch vault" },
		{ "<leader>Oo", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: open in app" },
		{ "<leader>Or", "<cmd>ObsidianRename<cr>", desc = "Obsidian: rename note" },
		{ "<leader>Op", "<cmd>ObsidianPasteImg<cr>", desc = "Obsidian: paste image" },
		{ "<leader>Ol", ":ObsidianLink<cr>", mode = "v", desc = "Obsidian: link selection" },
		{ "<leader>On", ":ObsidianLinkNew<cr>", mode = "v", desc = "Obsidian: link selection to new note" },
		{ "<leader>Oe", ":ObsidianExtractNote<cr>", mode = "v", desc = "Obsidian: extract to new note" },
	},
	opts = {
		workspaces = vaults,
		-- show raw markdown: no concealed links/checkbox rendering
		ui = { enable = false },
		-- notes are named by title like in the Obsidian app, not zettel ids
		note_id_func = function(title)
			return title or tostring(os.time())
		end,
		new_notes_location = "notes_subdir",
		-- don't rewrite existing notes with YAML frontmatter on save
		disable_frontmatter = true,
		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},
		picker = { name = "telescope.nvim" },
		attachments = { img_folder = "_attachments" },
		-- <CR>/gf on a [[link]] follows it; <leader>ch toggles a checkbox
		mappings = {
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			["<leader>ch"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
			["<cr>"] = {
				action = function()
					return require("obsidian").util.smart_action()
				end,
				opts = { buffer = true, expr = true },
			},
		},
	},
}
