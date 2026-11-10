-- Insert today's calendar and reminders into notes via ical-guy (macOS,
-- EventKit). We ask for JSON and format in Lua rather than piping ical-guy's
-- text output through grep/sed: its text mode ignores --date-format and
-- --bullet for reminders, can't hide recurrence, and shell quoting through
-- Vim's cmdline is fragile.
local M = {}

local ICALGUY = "/opt/homebrew/bin/ical-guy"
local INDENT = "    * "

local excluded_cal_types = "subscription,birthday"
local excluded_calendars = "Family,HomeAW"
-- Apple Reminders lists we never want pulled into notes
local excluded_reminder_lists = table.concat({
  "Groceries", "McGuckins", "Clothing Wishlist", "Costco", "Brenda",
  "Hazel's Beverage", "Family", "Errands", "Target type store",
}, ",")

-- ical-guy emits UTC ISO-8601 stamps ("2026-09-01T06:00:00Z"); convert to an
-- epoch so os.date renders local time (and all-day items land on the right day).
local function utc_iso_to_epoch(iso)
  local y, mo, d, h, mi, s = (iso or ""):match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not y then return nil end
  -- os.time() reads the table as local time; correct by this zone's UTC offset
  local t = os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = s })
  local loc, utc = os.date("*t", t), os.date("!*t", t)
  utc.isdst = loc.isdst -- else os.time() assumes standard time and DST dates shift an hour
  return t + os.difftime(os.time(loc), os.time(utc))
end

local function fmt_time(epoch)
  return os.date("%-I:%M %p", epoch)
end

-- Run ical-guy with JSON output; returns the decoded list or nil after notifying.
local function fetch(args, title)
  local cmd = { ICALGUY }
  vim.list_extend(cmd, args)
  vim.list_extend(cmd, { "--format", "json" })
  local ok, proc = pcall(vim.system, cmd, { text = true })
  if not ok then
    vim.notify("ical-guy not runnable: " .. tostring(proc), vim.log.levels.ERROR, { title = title })
    return nil
  end
  local result = proc:wait(15000)
  if result.code ~= 0 then
    local err = vim.trim(result.stderr or "")
    if err == "" then err = "ical-guy failed (code " .. tostring(result.code) .. ")" end
    vim.notify(err, vim.log.levels.ERROR, { title = title })
    return nil
  end
  local decoded_ok, items = pcall(vim.json.decode, result.stdout or "")
  if not decoded_ok or type(items) ~= "table" then
    vim.notify("Could not parse ical-guy output", vim.log.levels.ERROR, { title = title })
    return nil
  end
  return items
end

-- Insert lines below the cursor (like :r!), or say there was nothing.
local function insert_below(lines, title)
  if #lines == 0 then
    vim.notify("Nothing to insert", vim.log.levels.INFO, { title = title })
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end

local function format_event(e)
  local when
  if e.isAllDay then
    when = "All day"
  else
    when = fmt_time(utc_iso_to_epoch(e.startDate)) .. " - " .. fmt_time(utc_iso_to_epoch(e.endDate))
  end
  local lines = { "* " .. when .. "  " .. (e.title or "") }
  if e.location and e.location ~= "" then
    table.insert(lines, INDENT .. "Location: " .. e.location)
  end
  if e.meetingUrl and e.meetingUrl ~= "" then
    table.insert(lines, INDENT .. "Meeting: " .. e.meetingUrl)
  end
  local others = vim.tbl_filter(function(a) return not a.isCurrentUser end, e.attendees or {})
  if #others > 0 then
    table.insert(lines, INDENT .. "Attendees:")
    for _, a in ipairs(others) do
      local who = a.email or a.name or "?"
      if a.name and a.email and a.name ~= a.email then
        who = a.name .. " <" .. a.email .. ">"
      end
      table.insert(lines, "    " .. INDENT .. who .. " (" .. (a.status or "unknown") .. ")")
    end
  end
  return lines
end

-- Render a reminder as a markdown task matching pwnvim.tasks conventions:
-- "* [ ] title [list] @due(YYYY-MM-DD)" and "@done(YYYY-MM-DD h:mm PM)".
local function format_reminder(r)
  local parts = { "* [" .. (r.isCompleted and "x" or " ") .. "] " .. (r.title or "") }
  if r.list and r.list.title then table.insert(parts, "[" .. r.list.title .. "]") end
  local due = utc_iso_to_epoch(r.dueDate)
  if due then table.insert(parts, "@due(" .. os.date("%Y-%m-%d", due) .. ")") end
  local done = utc_iso_to_epoch(r.completionDate)
  if r.isCompleted and done then
    table.insert(parts, "@done(" .. os.date("%Y-%m-%d ", done) .. fmt_time(done) .. ")")
  end
  local lines = { table.concat(parts, " ") }
  for _, note in ipairs(vim.split(vim.trim(r.notes or ""), "\n", { trimempty = true })) do
    table.insert(lines, INDENT .. vim.trim(note))
  end
  return lines
end

-- Today's events (excluding subscribed/birthday calendars and family ones)
M.insertCalendar = function()
  local events = fetch({ "events", "list", "--from", "today",
    "--exclude-cal-types", excluded_cal_types,
    "--exclude-calendars", excluded_calendars }, "Calendar")
  if not events then return end
  local lines = {}
  for _, e in ipairs(events) do vim.list_extend(lines, format_event(e)) end
  insert_below(lines, "Calendar")
end

-- Open reminders due within the next week (including overdue), then
-- reminders completed today.
M.insertReminders = function()
  local base = { "reminders", "list", "--exclude-lists", excluded_reminder_lists }
  local open = fetch(vim.list_extend(vim.deepcopy(base), { "--to", "today+7" }), "Reminders")
  if not open then return end
  local completed = fetch(vim.list_extend(vim.deepcopy(base), { "--completed", "--from", "today" }), "Reminders") or {}
  local lines = {}
  for _, group in ipairs({ open, completed }) do
    for _, r in ipairs(group) do vim.list_extend(lines, format_reminder(r)) end
  end
  insert_below(lines, "Reminders")
end

return M
