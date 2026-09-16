-- AI agent client driving the `claude` CLI (must be on PATH)
return {
  "ThePrimeagen/99",
  dependencies = { "nvim-telescope/telescope.nvim" },
  keys = {
    { "<leader>9v", function() require("99").visual() end, mode = "v", desc = "99 replace selection" },
    { "<leader>9s", function() require("99").search() end, desc = "99 search project" },
    { "<leader>9b", function() require("99").vibe() end, desc = "99 vibe session" },
    { "<leader>9o", function() require("99").open() end, desc = "99 open last result" },
    { "<leader>9x", function() require("99").stop_all_requests() end, desc = "99 stop all requests" },
    { "<leader>9l", function() require("99").view_logs() end, desc = "99 view logs" },
    { "<leader>9m", function() require("99.extensions.telescope").select_model() end, desc = "99 select model" },
    { "<leader>9p", function() require("99.extensions.telescope").select_provider() end, desc = "99 select provider" },
  },
  config = function()
    local _99 = require("99")
    _99.setup({
      provider = _99.Providers.ClaudeCodeProvider,
      tmp_dir = "./tmp",
      completion = {
        source = "cmp",
      },
      md_files = { "CLAUDE.md", "AGENT.md" },
    })
  end,
}
