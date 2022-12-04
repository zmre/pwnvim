local M = {}

M.completeTask = function()
  -- local pos = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  -- local nline = line:sub(0, pos) .. 'hello' .. line:sub(pos + 1)
  local nline = line:gsub("%[ %]", "[x]", 1)
  if line ~= nline then
    vim.api.nvim_set_current_line(nline .. ' @done(' .. os.date("%Y-%m-%d %-I:%M %p") .. ")")
  end
end

M.scheduleTask = function(newyear, newmonth, newday)
  -- Step 1: change current task to [>]
  local line = vim.api.nvim_get_current_line()
  local nline = line:gsub("%[[ oO>-]%] ", "[>] ", 1)
  if line == nline then
    print("This line does not look like an open task")
    return
  end

  -- Step 2: add scheduled date to end as ">YYYY-mm-dd" removing any existing ">date" tags
  nline = nline:gsub(">[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]?", "")
  nline = nline .. " >" .. newyear .. "-" .. newmonth .. "-" .. newday
  vim.api.nvim_set_current_line(nline)

  -- Step 3: try to get the date from the current note
  local date = require("pwnvim.tasks").getDateFromCurrentFile()

  -- Step 4: add "<YYYY-mm-dd" to end of the copied task if it doesn't already have a date
  --         and if we can glean a source date from a date in the filename or frontmatter
  --         or worst case, just don't put that
  if line:match("<%d+-%d+-%d+") == nil and date ~= nil then
    line = line .. " <" .. date
  end

  -- Step 5: take current task and copy it to Calendar/YYYYmmdd.md
  local dir = vim.env.ZK_NOTEBOOK_DIR .. '/Calendar/'
  local target = dir .. newyear .. newmonth .. newday .. '.md'
  local title = newyear .. newmonth .. newday
  require("zk.api").new(target, { dir = dir, title = title, template = "daily.md", edit = true },
    function(err, res)
      vim.api.nvim_command('edit ' .. target)
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { line })
    end)
end

M.scheduleTaskPrompt = function()
  local defaultyear = os.date("%Y")
  local defaultmonth = os.date("%m")
  local defaultday = os.date("%d")
  vim.ui.input({ prompt = "Enter year: ", default = defaultyear }, function(year)
    vim.ui.input({ prompt = "Enter month: ", default = defaultmonth }, function(month)
      vim.ui.input({ prompt = "Enter day: ", default = defaultday }, function(day)
        require("pwnvim.tasks").scheduleTask(year, month, day)
      end)
    end)
  end)
end

M.scheduleTaskToday = function()
  local year = os.date("%Y")
  local month = os.date("%m")
  local day = os.date("%d")
  require("pwnvim.tasks").scheduleTask(year, month, day)
end

M.getDateFromCurrentFile = function()
  local srcfilename = vim.api.nvim_buf_get_name(0)
  local date = srcfilename:match("%d+-%d+-%d+")
  if date == nil then
    local srcheader = vim.api.nvim_buf_get_lines(0, 0, 10, false)
    for _, l in ipairs(srcheader) do
      date = l:match("^[dD]ate: (%d+-%d+-%d+)")
      if date ~= nil then break end
    end
  end
  return date
end

M.createTask = function()
  local line = vim.api.nvim_get_current_line()
  local nline = line:gsub("^%s*[-*] ", "%0[ ] ", 1)
  if line == nline then
    nline = line:gsub("^%s*", "%0* [ ] ", 1)
  end
  vim.api.nvim_set_current_line(nline)
  vim.cmd("normal 4l")
end

return M
