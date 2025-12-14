-- Test validation helpers for pwnvim
-- Used by check.sh for automated testing

local M = {}

-- List of required plugins that must load successfully
M.required_plugins = {
  { name = "snacks.nvim", test = function() return Snacks ~= nil end },
  { name = "which-key", test = function() return pcall(require, "which-key") end },
  { name = "nvim-treesitter", test = function() return pcall(require, "nvim-treesitter") end },
  { name = "gitsigns", test = function() return pcall(require, "gitsigns") end },
  { name = "lualine", test = function() return pcall(require, "lualine") end },
  { name = "blink.cmp", test = function() return pcall(require, "blink.cmp") end },
  { name = "oil", test = function() return pcall(require, "oil") end },
  { name = "conform", test = function() return pcall(require, "conform") end },
  { name = "nvim-lint", test = function() return pcall(require, "lint") end },
  { name = "trouble", test = function() return pcall(require, "trouble") end },
  { name = "flash", test = function() return pcall(require, "flash") end },
  { name = "noice", test = function() return pcall(require, "noice") end },
  { name = "nvim-surround", test = function() return pcall(require, "nvim-surround") end },
}

-- Validate all required plugins are loaded
-- Returns: passed (table), failed (table)
M.validate_plugins = function()
  local passed = {}
  local failed = {}

  for _, plugin in ipairs(M.required_plugins) do
    local ok, result = pcall(plugin.test)
    if ok and result then
      table.insert(passed, plugin.name)
    else
      table.insert(failed, plugin.name)
    end
  end

  return passed, failed
end

-- Check for duplicate keymaps in a given mode
-- Returns: table of duplicate keys
M.find_keymap_conflicts = function(mode)
  mode = mode or "n"
  local maps = vim.api.nvim_get_keymap(mode)
  local seen = {}
  local conflicts = {}

  for _, map in ipairs(maps) do
    local key = map.lhs
    if seen[key] then
      -- Only report if both mappings do different things
      if seen[key].rhs ~= map.rhs then
        table.insert(conflicts, {
          key = key,
          first = seen[key].desc or seen[key].rhs or "unknown",
          second = map.desc or map.rhs or "unknown",
        })
      end
    else
      seen[key] = map
    end
  end

  return conflicts
end

-- Get any error messages from :messages
-- Returns: table of error messages
M.get_startup_errors = function()
  local messages = vim.api.nvim_exec2("messages", { output = true }).output
  local errors = {}

  for line in messages:gmatch("[^\n]+") do
    -- Match vim error patterns
    if line:match("^E%d+:") or line:match("Error") or line:match("error:") then
      table.insert(errors, line)
    end
  end

  return errors
end

-- Check if specific snacks features are enabled
M.check_snacks_features = function()
  local features = {
    "picker",
    "dashboard",
    "bufdelete",
    "terminal",
    "zen",
    "gitbrowse",
    "indent",
    "scroll",
  }

  local enabled = {}
  local disabled = {}

  for _, feature in ipairs(features) do
    -- Try to access the feature
    local ok = pcall(function()
      return Snacks[feature] ~= nil
    end)
    if ok then
      table.insert(enabled, feature)
    else
      table.insert(disabled, feature)
    end
  end

  return enabled, disabled
end

-- Run all validations and print results
M.run_all = function()
  print("=" .. string.rep("=", 59))
  print("  pwnvim Validation Results")
  print("=" .. string.rep("=", 59))

  -- Plugin check
  print("\n[Plugins]")
  local passed, failed = M.validate_plugins()
  print("  Passed: " .. table.concat(passed, ", "))
  if #failed > 0 then
    print("  FAILED: " .. table.concat(failed, ", "))
  end

  -- Keymap check
  print("\n[Keymaps]")
  local conflicts = M.find_keymap_conflicts("n")
  if #conflicts > 0 then
    print("  Conflicts found:")
    for _, c in ipairs(conflicts) do
      print(string.format("    %s: '%s' vs '%s'", c.key, c.first, c.second))
    end
  else
    print("  No conflicts in normal mode")
  end

  -- Startup errors
  print("\n[Startup Errors]")
  local errors = M.get_startup_errors()
  if #errors > 0 then
    for _, err in ipairs(errors) do
      print("  " .. err)
    end
  else
    print("  None detected")
  end

  -- Snacks features
  print("\n[Snacks Features]")
  local enabled, disabled = M.check_snacks_features()
  print("  Enabled: " .. table.concat(enabled, ", "))
  if #disabled > 0 then
    print("  Disabled: " .. table.concat(disabled, ", "))
  end

  print("\n" .. string.rep("=", 60))

  -- Return exit code
  return #failed == 0 and #errors == 0
end

return M
