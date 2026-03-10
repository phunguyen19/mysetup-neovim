-- Git worktree manager with telescope integration
-- Uses auto-session for session save/restore during worktree switches

---@param args string[]
---@param opts? { cwd?: string }
---@return string[]|nil, string|nil
local function git_cmd(args, opts)
  local cmd = vim.list_extend({ "git" }, args)
  local sys_opts = { text = true }
  if opts and opts.cwd then
    sys_opts.cwd = opts.cwd
  end
  local result = vim.system(cmd, sys_opts):wait()
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

---@param git_root string
local function get_existing_ignored_files(git_root)
  local lines = git_cmd(
    { "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
    { cwd = git_root }
  )
  if not lines then
    return {}
  end
  -- Remove trailing slashes from directory entries for consistent display
  local items = {}
  for _, line in ipairs(lines) do
    local cleaned = line:gsub("/$", "")
    if cleaned ~= "" then
      table.insert(items, cleaned)
    end
  end
  return items
end

local function copy_items_to_worktree(source_root, dest_path, items)
  local failed = {}
  for _, item in ipairs(items) do
    -- Reject path traversal or absolute paths
    if item:match("%.%.") or item:match("^/") then
      table.insert(failed, item)
    else
      local src = source_root .. "/" .. item
      local dst = dest_path .. "/" .. item
      -- Ensure parent directory exists
      local parent = vim.fn.fnamemodify(dst, ":h")
      vim.fn.mkdir(parent, "p")
      local result = vim.system({ "cp", "-a", src, dst }, { text = true }):wait()
      if result.code ~= 0 then
        table.insert(failed, item)
      end
    end
  end
  return failed
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

  local parent_dir = vim.fn.fnamemodify(git_root, ":h")

  vim.ui.input({ prompt = "Worktree path: ", default = parent_dir .. "/" }, function(path)
    if not path or path == "" then
      return
    end

    if vim.fn.isdirectory(path) == 1 then
      notify("Path already exists: " .. path, vim.log.levels.ERROR)
      return
    end

    -- Derive default branch name from folder basename
    local basename = vim.fn.fnamemodify(path, ":t")
    local default_branch = basename:gsub("[%s]+", "-")

    vim.ui.input({ prompt = "Branch name: ", default = default_branch }, function(branch)
      if not branch or branch == "" then
        return
      end

      -- Strip origin/ prefix if present
      local local_branch = branch:gsub("^origin/", "")

      if not is_valid_branch_name(local_branch) then
        notify("Invalid branch name: " .. local_branch, vim.log.levels.ERROR)
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

      local function offer_switch()
        vim.ui.select({ "Yes", "No" }, { prompt = "Switch to new worktree?" }, function(choice)
          if choice == "Yes" then
            switch_worktree(path)
          end
        end)
      end

      local ignored = get_existing_ignored_files(git_root)
      if #ignored == 0 then
        offer_switch()
        return
      end

      vim.ui.select({ "Yes", "No" }, {
        prompt = string.format("Copy ignored files to new worktree? (%d found)", #ignored),
      }, function(copy_choice)
        if copy_choice ~= "Yes" then
          offer_switch()
          return
        end

        -- Use telescope multi-select picker for ignored files
        local ok_telescope, _ = pcall(require, "telescope")
        if not ok_telescope then
          -- Fallback: copy all ignored files
          local failed = copy_items_to_worktree(git_root, path, ignored)
          if #failed > 0 then
            notify("Failed to copy: " .. table.concat(failed, ", "), vim.log.levels.WARN)
          else
            notify(string.format("Copied %d ignored item(s)", #ignored))
          end
          offer_switch()
          return
        end

        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        pickers
          .new({}, {
            prompt_title = "Select ignored files to copy (Tab to toggle, Enter to confirm)",
            finder = finders.new_table({ results = ignored }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                local picker = action_state.get_current_picker(prompt_bufnr)
                local selections = picker:get_multi_selection()
                actions.close(prompt_bufnr)

                local to_copy
                if #selections > 0 then
                  to_copy = vim.tbl_map(function(e) return e[1] end, selections)
                else
                  -- No multi-selection: copy the single highlighted entry
                  local entry = action_state.get_selected_entry()
                  if entry then
                    to_copy = { entry[1] }
                  end
                end

                if not to_copy or #to_copy == 0 then
                  offer_switch()
                  return
                end

                notify(string.format("Copying %d item(s)...", #to_copy))
                local failed = copy_items_to_worktree(git_root, path, to_copy)
                if #failed > 0 then
                  notify("Failed to copy: " .. table.concat(failed, ", "), vim.log.levels.WARN)
                else
                  notify(string.format("Copied %d ignored item(s)", #to_copy))
                end
                offer_switch()
              end)

              -- Handle picker dismissal so the switch prompt still appears
              local function on_dismiss()
                actions.close(prompt_bufnr)
                offer_switch()
              end
              map("i", "<Esc>", on_dismiss)
              map("n", "q", on_dismiss)
              map("n", "<Esc>", on_dismiss)

              return true
            end,
          })
          :find()
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
