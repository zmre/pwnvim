local M = {}

M.completeTaskDirect = function()
  local line = vim.api.nvim_get_current_line()
  local nline = require("pwnvim.tasks").completeTask(line)
  vim.api.nvim_set_current_line(nline)
end

M.completeTask = function(line)
  local nline = line:gsub("%[[ oO]%]", "[x]", 1)
  if line ~= nline then -- substitution successful, now add date completed
    nline = nline .. ' @done(' .. os.date("%Y-%m-%d %-I:%M %p") .. ")"
    return nline
  else -- or do nothing
    return line
  end
end

M.scheduleTaskDirect = function(newyear, newmonth, newday)
  local line = vim.api.nvim_get_current_line()
  local nline = require("pwnvim.tasks").scheduleTask(line, newyear, newmonth, newday)
  vim.api.nvim_set_current_line(nline)
end

M.scheduleTask = function(line, newyear, newmonth, newday)
  newmonth = string.format("%02d", newmonth)
  newday = string.format("%02d", newday)
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  -- Step 0: ignore tasks that are complete or canceled
  if line:match("%[[xX-]%] ") ~= nil then
    return line
  end

  -- Step 1: change current task to [>]
  local nline = line:gsub("%[[ oO>]%] ", "[>] ", 1)
  if line ~= nline then
    -- if we're here, this is a task
    -- if the line isn't a task, we're still copying it over, just without all the modifications
    -- Step 2: add scheduled date to end as ">YYYY-mm-dd" removing any existing ">date" tags
    nline = nline:gsub(">[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]?", "")
    nline = nline .. " >" .. newyear .. "-" .. newmonth .. "-" .. newday
    --vim.api.nvim_set_current_line(nline)

    -- Step 3: try to get the date from the current note
    local date = require("pwnvim.tasks").getDateFromCurrentFile()

    -- Step 4: add "<YYYY-mm-dd" to end of the copied task if it doesn't already have a date
    --         and if we can glean a source date from a date in the filename or frontmatter
    --         or worst case, just don't put that
    if line:match("<%d+-%d+-%d+") == nil and date ~= nil then
      line = line .. " <" .. date
    end
  end


  -- Step 5: take current task and copy it to Calendar/YYYYmmdd.md
  local target = vim.env.ZK_NOTEBOOK_DIR .. '/Calendar/' .. newyear .. newmonth .. newday .. '.md'
  vim.api.nvim_command('edit ' .. target)
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { line })

  vim.api.nvim_set_current_win(win)
  vim.api.nvim_set_current_buf(buf)

  return nline
end

M.scheduleTaskBulk = function()
  require("pwnvim.tasks").datePromptThen(function(year, month, day)
    vim.cmd("'<,'>luado return require('pwnvim.tasks').scheduleTask(line,'" ..
      year .. "','" .. month .. "','" .. day .. "')")
  end)
end

M.scheduleTaskPrompt = function()
  require("pwnvim.tasks").datePromptThen(require("pwnvim.tasks").scheduleTaskDirect)
end

M.datePromptThen = function(myfunc)
  local days = {}
  -- Generate dates for next two weeks with handy shortcut labels
  for i = 0, 14, 1 do
    local day
    if i == 0 then
      day = os.date("%Y-%m-%d (today)", os.time() + 86400 * i)
    elseif i == 1 then
      day = os.date("%Y-%m-%d (tomorrow)", os.time() + 86400 * i)
    elseif i > 7 then
      day = os.date("%Y-%m-%d (next %a)", os.time() + 86400 * i)
    else
      day = os.date("%Y-%m-%d (%a)", os.time() + 86400 * i)
    end
    table.insert(days, day)
  end
  -- These will pop up in telescope for quick filtering
  vim.ui.select(days, { prompt = 'Pick a date:' }, function(choice)
    if choice then
      local t = {}
      for w in string.gmatch(choice, "(%d+)") do
        table.insert(t, w)
      end
      if #t == 3 then
        myfunc(t[1], t[2], t[3])
      end
    else
      -- if no choice was made, assume a desire to specify something outside the 14 days
      M.datePromptRawThen(myfunc)
    end
  end)
end

-- Just give three prompts for year/month/day
M.datePromptRawThen = function(myfunc)
  local defaultyear = os.date("%Y")
  local defaultmonth = os.date("%m")
  local defaultday = os.date("%d")
  vim.ui.input({ prompt = "Enter year: ", default = defaultyear }, function(year)
    vim.ui.input({ prompt = "Enter month: ", default = defaultmonth }, function(month)
      vim.ui.input({ prompt = "Enter day: ", default = defaultday }, function(day)
        month = string.format("%02d", month)
        day = string.format("%02d", day)
        myfunc(year, month, day)
      end)
    end)
  end)
end

M.scheduleTaskTodayDirect = function()
  local year = os.date("%Y")
  local month = os.date("%m")
  local day = os.date("%d")
  require("pwnvim.tasks").scheduleTaskDirect(year, month, day)
end

M.scheduleTaskToday = function(line)
  local year = os.date("%Y")
  local month = os.date("%m")
  local day = os.date("%d")
  return require("pwnvim.tasks").scheduleTask(line, year, month, day)
end

M.getDateFromCurrentFile = function()
  local srcfilename = vim.api.nvim_buf_get_name(0)
  local date = srcfilename:match("%d+-%d+-%d+")
  -- TODO: also check for filenames that are "YYYYmmdd.md"
  if date == nil then
    local srcheader = vim.api.nvim_buf_get_lines(0, 0, 10, false)
    for _, l in ipairs(srcheader) do
      date = l:match("^[dD]ate: (%d+-%d+-%d+)")
      if date ~= nil then break end
    end
  end
  return date
end

M.createTask = function(line)
  local nline = line:gsub("^%s*[-*] ", "%0[ ] ", 1)
  if line == nline then
    nline = line:gsub("^%s*", "%0* [ ] ", 1)
  end
  return nline
end

M.createTaskDirect = function()
  local line = vim.api.nvim_get_current_line()
  local nline = require("pwnvim.tasks").createTask(line)
  vim.api.nvim_set_current_line(nline)
  vim.cmd("normal 4l")
end


local function visual_selection_range()
  local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
  local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  if csrow < cerow or (csrow == cerow and cscol <= cecol) then
    return csrow - 1, cscol - 1, cerow - 1, cecol
  else
    return cerow - 1, cecol - 1, csrow - 1, cscol
  end
end

M.eachSelectedLine = function(myfunc)
  -- local rowstart, _, rowend, _ = visual_selection_range()
  local rowstart = vim.api.nvim_buf_get_mark(0, "<")[1] - 1
  local rowend = vim.api.nvim_buf_get_mark(0, ">")[1] - 1
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  print("row start:" .. rowstart .. " row end:" .. rowend)

  for i = rowstart, rowend do
    print("i:" .. i)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, { i + 1, 0 })
    -- All we're really doing here is putting the cursor on each line of the selection
    myfunc()
  end
end

return M
