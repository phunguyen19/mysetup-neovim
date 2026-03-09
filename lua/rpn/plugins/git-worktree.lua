-- Git worktree manager with telescope integration
-- Uses auto-session for session save/restore during worktree switches

---@param args string[]
---@return string[]|nil, string|nil
local function git_cmd(args)
  local cmd = vim.list_extend({ "git" }, args)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or result.stdout or "unknown error")
  end
  local lines = vim.split(vim.trim(result.stdout or ""), "\n", { trimempty = true })
  return lines
end

local function get_git_root()
  local result = git_cmd({ "rev-parse", "--show-toplevel" })
  if not result then
    return nil
  end
  return result[1]
end

local function parse_worktrees()
  local result = git_cmd({ "worktree", "list", "--porcelain" })
  if not result then
    return {}
  end

  local worktrees = {}
  local current = {}

  for _, line in ipairs(result) do
    if line:match("^worktree ") then
      current = { path = line:match("^worktree (.+)") }
    elseif line:match("^HEAD ") then
      current.head = line:match("^HEAD (.+)")
    elseif line:match("^branch ") then
      current.branch = line:match("^branch refs/heads/(.+)")
    elseif line == "bare" then
      current.bare = true
    elseif line == "" then
      if current.path then
        table.insert(worktrees, current)
      end
      current = {}
    end
  end

  -- Handle last entry (no trailing blank line)
  if current.path then
    table.insert(worktrees, current)
  end

  return worktrees
end

---@param branch string
---@return boolean
local function is_valid_branch_name(branch)
  return branch:match("^[%w%.%-_/]+$") ~= nil
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git Worktree" })
end

local function check_unsaved_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      return true
    end
  end
  return false
end

local function normalize_path(p)
  return vim.fs.normalize(vim.fn.resolve(p))
end

-- Core switch logic (no unsaved-buffer check)
local function do_switch(path)
  -- Suppress "Press ENTER" prompts during switch
  local saved_cmdheight = vim.o.cmdheight
  vim.o.cmdheight = 2

  -- Save current session
  pcall(vim.cmd, "silent! AutoSession save")

  -- Wipe all buffers
  vim.cmd("silent! %bwipeout!")

  -- Change directory
  vim.api.nvim_set_current_dir(path)
  vim.cmd("tcd " .. vim.fn.fnameescape(path))

  -- Restore session for new worktree
  local ok = pcall(vim.cmd, "silent! AutoSession restore")
  if not ok then
    -- Fall back to file explorer or empty buffer
    if pcall(vim.cmd, "NvimTreeOpen") then
      -- file explorer opened
    else
      vim.cmd("enew")
    end
  end

  vim.o.cmdheight = saved_cmdheight

  -- Open file explorer after switch
  vim.defer_fn(function()
    pcall(vim.cmd, "NvimTreeOpen")
    pcall(vim.cmd, "LspRestart")
  end, 200)

  notify("Switched to worktree: " .. path)
end

local function switch_worktree(path)
  if check_unsaved_buffers() then
    vim.ui.select({ "Save all and switch", "Discard and switch", "Cancel" }, {
      prompt = "Unsaved buffers detected:",
    }, function(choice)
      if choice == "Save all and switch" then
        vim.cmd("wall")
      elseif choice ~= "Discard and switch" then
        return
      end
      do_switch(path)
    end)
    return
  end

  do_switch(path)
end

local function create_worktree()
  local git_root = get_git_root()
  if not git_root then
    notify("Not a git repository", vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "Branch name: " }, function(branch)
    if not branch or branch == "" then
      return
    end

    -- Strip origin/ prefix if present
    local local_branch = branch:gsub("^origin/", "")

    if not is_valid_branch_name(local_branch) then
      notify("Invalid branch name: " .. local_branch, vim.log.levels.ERROR)
      return
    end

    local sanitized = local_branch:gsub("[/%s]+", "-")
    local parent_dir = vim.fn.fnamemodify(git_root, ":h")
    local default_path = parent_dir .. "/" .. sanitized

    vim.ui.input({ prompt = "Worktree path: ", default = default_path }, function(path)
      if not path or path == "" then
        return
      end

      if vim.fn.isdirectory(path) == 1 then
        notify("Path already exists: " .. path, vim.log.levels.ERROR)
        return
      end

      -- Check if branch exists locally or remotely
      local branch_exists = git_cmd({ "rev-parse", "--verify", "refs/heads/" .. local_branch })
      local remote_exists = git_cmd({ "rev-parse", "--verify", "refs/remotes/origin/" .. local_branch })

      local cmd
      if branch_exists then
        cmd = { "worktree", "add", path, local_branch }
      elseif remote_exists then
        cmd = { "worktree", "add", "-b", local_branch, path, "origin/" .. local_branch }
      else
        cmd = { "worktree", "add", "-b", local_branch, path }
      end

      local _, err = git_cmd(cmd)
      if err then
        notify("Failed to create worktree: " .. err, vim.log.levels.ERROR)
        return
      end

      notify("Created worktree: " .. path)

      vim.ui.select({ "Yes", "No" }, { prompt = "Switch to new worktree?" }, function(choice)
        if choice == "Yes" then
          switch_worktree(path)
        end
      end)
    end)
  end)
end

---@param wt { path: string, branch: string|nil, head: string|nil }
local function delete_worktree(wt)
  local cwd = normalize_path(vim.fn.getcwd())
  if cwd == normalize_path(wt.path) then
    notify("Cannot delete the current worktree", vim.log.levels.ERROR)
    return
  end

  local branch_label = wt.branch and (" (branch: " .. wt.branch .. ")") or ""
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Delete worktree at " .. wt.path .. branch_label .. "?",
  }, function(choice)
    if choice ~= "Yes" then
      return
    end

    local function post_delete()
      git_cmd({ "worktree", "prune" })
      -- Refresh gitsigns to avoid stale worktree HEAD reads
      vim.defer_fn(function()
        local ok, gitsigns = pcall(require, "gitsigns")
        if ok then
          gitsigns.refresh()
        end
      end, 100)
    end

    local function delete_branch()
      if not wt.branch then
        post_delete()
        return
      end
      local _, branch_err = git_cmd({ "branch", "-d", wt.branch })
      if branch_err then
        vim.ui.select({ "Force delete branch", "Keep branch" }, {
          prompt = "Branch not fully merged. " .. branch_err,
        }, function(branch_choice)
          if branch_choice == "Force delete branch" then
            local _, force_branch_err = git_cmd({ "branch", "-D", wt.branch })
            if force_branch_err then
              notify("Failed to delete branch: " .. force_branch_err, vim.log.levels.ERROR)
            else
              notify("Branch deleted: " .. wt.branch)
            end
          end
          post_delete()
        end)
      else
        notify("Branch deleted: " .. wt.branch)
        post_delete()
      end
    end

    local _, err = git_cmd({ "worktree", "remove", wt.path })
    if err then
      vim.ui.select({ "Force delete", "Cancel" }, {
        prompt = "Worktree has changes. " .. err,
      }, function(force_choice)
        if force_choice == "Force delete" then
          local _, force_err = git_cmd({ "worktree", "remove", "--force", wt.path })
          if force_err then
            notify("Force delete failed: " .. force_err, vim.log.levels.ERROR)
          else
            notify("Worktree deleted (forced): " .. wt.path)
            delete_branch()
          end
        end
      end)
      return
    end

    notify("Worktree deleted: " .. wt.path)
    delete_branch()
  end)
end

local function list_worktrees()
  local git_root = get_git_root()
  if not git_root then
    notify("Not a git repository", vim.log.levels.ERROR)
    return
  end

  local worktrees = parse_worktrees()
  if #worktrees == 0 then
    notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local cwd = normalize_path(vim.fn.getcwd())

  pickers
    .new({}, {
      prompt_title = "Git Worktrees",
      finder = finders.new_table({
        results = worktrees,
        entry_maker = function(wt)
          local is_current = normalize_path(wt.path) == cwd
          local branch_display = wt.branch or (wt.head and wt.head:sub(1, 7)) or "(detached)"
          local display = string.format(
            "%s │ %s%s",
            branch_display,
            wt.path,
            is_current and " (current)" or ""
          )

          return {
            value = wt,
            display = display,
            ordinal = (wt.branch or "") .. " " .. wt.path,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = action_state.get_selected_entry()
          if entry then
            switch_worktree(entry.value.path)
          end
        end)

        map("i", "<C-d>", function()
          local entry = action_state.get_selected_entry()
          if entry then
            actions.close(prompt_bufnr)
            delete_worktree(entry.value)
          end
        end)

        map("n", "<C-d>", function()
          local entry = action_state.get_selected_entry()
          if entry then
            actions.close(prompt_bufnr)
            delete_worktree(entry.value)
          end
        end)

        return true
      end,
    })
    :find()
end

return {
  dir = vim.fn.stdpath("config"),
  name = "git-worktree",
  dependencies = { "nvim-telescope/telescope.nvim" },
  keys = {
    { "<leader>gwl", list_worktrees, desc = "Git worktree list" },
    { "<leader>gwc", create_worktree, desc = "Git worktree create" },
    { "<leader>gwd", list_worktrees, desc = "Git worktree delete (via list)" },
  },
  cmd = { "GitWorktreeList", "GitWorktreeCreate" },
  config = function()
    vim.api.nvim_create_user_command("GitWorktreeList", list_worktrees, {})
    vim.api.nvim_create_user_command("GitWorktreeCreate", create_worktree, {})
  end,
}
