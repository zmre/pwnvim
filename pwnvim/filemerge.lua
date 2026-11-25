-- Resolve "changed on disk AND in the buffer" conflicts.
--
-- We snapshot each buffer's disk contents whenever it is read, reloaded, or
-- written. That snapshot is the merge base ("original"): with base, buffer
-- ("yours") and the current disk file ("disk"), `git merge-file` merges every
-- non-overlapping change on both sides. git merge-file works on plain files,
-- so no repo is needed.
--
--   :FileMerge (,fm)  3-way merge in a new tab:
--                       left   YOURS   your unsaved buffer text (read-only)
--                       middle RESULT  the real buffer, what :w saves (editable)
--                       right  DISK    the file on disk now (read-only)
--                     The result starts as the auto-merge. Overlapping regions
--                     show the ORIGINAL text, flagged with a `!` sign, so you
--                     explicitly pick/blend each one.
--   :FileDiff         2-way diff split of buffer vs disk (no merge).
--
-- In RESULT: gh / gl take the hunk (or visual-selected lines) from yours /
-- disk, ]n [n jump conflicts, ]c [c jump hunks, q closes. In YOURS / DISK:
-- dp pushes the hunk (or selected lines) into RESULT.

local M = {}

-- Snapshots are whole-file copies; skip huge files to bound memory.
M.max_base_bytes = 2 * 1024 * 1024

local bases = {} ---@type table<integer, string[]>
local ns = vim.api.nvim_create_namespace("pwnvim_filemerge")
local ns_start = vim.api.nvim_create_namespace("pwnvim_filemerge_start")

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "File merge" })
end

local function is_file_buf(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
end

-- Read a file as lines the way the buffer would see them (strip CR for dos ff).
local function read_lines(path, buf)
  if vim.fn.filereadable(path) ~= 1 then return nil end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return nil end
  if vim.bo[buf].fileformat == "dos" then
    for i, l in ipairs(lines) do lines[i] = l:gsub("\r$", "") end
  end
  return lines
end

local function record_base(buf)
  if not is_file_buf(buf) then return end
  local path = vim.api.nvim_buf_get_name(buf)
  local size = vim.fn.getfsize(path)
  if size < 0 or size > M.max_base_bytes then
    bases[buf] = nil
    return
  end
  bases[buf] = read_lines(path, buf)
end

-- 3-way merge with git merge-file. Non-overlapping changes are merged; each
-- overlapping region is replaced by its ORIGINAL (base) text and reported as
-- { start = 0-based row, count = lines } so the UI can flag it.
-- Returns { lines, conflicts } or nil + error.
local MARK = 31 -- long markers so file content can't be mistaken for them
local function merge3(ours, base, theirs)
  local files = {}
  for i, lines in ipairs({ ours, base, theirs }) do
    files[i] = vim.fn.tempname()
    vim.fn.writefile(lines, files[i])
  end
  local cmd = { "git", "merge-file", "-p", "--diff3", "--marker-size=" .. MARK,
    "-L", "yours", "-L", "original", "-L", "disk", files[1], files[2], files[3] }
  local ok, res = pcall(function() return vim.system(cmd, { text = true }):wait() end)
  for _, f in ipairs(files) do os.remove(f) end
  if not ok then return nil, tostring(res) end
  -- exit code = number of conflicts (capped at 127); negative (>127 unsigned) = error
  if res.code > 127 then return nil, vim.trim(res.stderr or "") end

  local out = vim.split(res.stdout or "", "\n", { plain = true })
  if out[#out] == "" then table.remove(out) end
  local open, mid, sep, close = ("<"):rep(MARK) .. " ", ("|"):rep(MARK) .. " ", ("="):rep(MARK), (">"):rep(MARK) .. " "
  local lines, conflicts, state, start = {}, {}, nil, 0
  for _, l in ipairs(out) do
    if state == nil and vim.startswith(l, open) then
      state = "yours"
    elseif state == "yours" and vim.startswith(l, mid) then
      state, start = "base", #lines
    elseif state == "base" and l == sep then
      state = "disk"
    elseif state == "disk" and vim.startswith(l, close) then
      table.insert(conflicts, { start = start, count = #lines - start })
      state = nil
    elseif state == nil or state == "base" then
      table.insert(lines, l)
    end
  end
  if state ~= nil then return nil, "unterminated conflict block in git merge-file output" end
  return { lines = lines, conflicts = conflicts }
end

-- Put `lines` in the buffer while re-syncing it with the file on disk.
-- Neovim's FileChangedShell path leaves the buffer's recorded mtime stale, so a
-- later :w would prompt "file has been changed since reading it". Reloading
-- with :e! refreshes that, then we set the content, undojoined so a single `u`
-- returns to the pre-merge text. undoreload is raised so the reload is undoable.
local function apply(buf, lines)
  local win = vim.fn.bufwinid(buf)
  local view = win ~= -1 and vim.api.nvim_win_call(win, vim.fn.winsaveview) or nil
  local undoreload = vim.o.undoreload
  vim.o.undoreload = math.max(undoreload, vim.api.nvim_buf_line_count(buf), #lines) + 1
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent edit!")
    pcall(vim.cmd.undojoin)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
  vim.o.undoreload = undoreload
  if view then vim.api.nvim_win_call(win, function() vim.fn.winrestview(view) end) end
end

-- render-markdown must be off in merge panes: with it rendering a markdown
-- buffer in diff mode, closing one of the diff windows while the cursor sits
-- in a hunk segfaults nvim (0.12.6 + render-markdown 8.14; fine with --clean or
-- non-markdown files). Raw text is what you want to see when merging anyway.
local function render_markdown(b, enable)
  if not package.loaded["render-markdown"] or not vim.api.nvim_buf_is_valid(b) then return end
  local ok, api = pcall(require, "render-markdown.api")
  if not ok then return end
  if enable and not api.get() then return end -- globally off: leave it off
  vim.api.nvim_buf_call(b, function() pcall(api.set_buf, enable) end)
end

-- Unnamed on purpose: giving these URL-like names (disk://...) made closing the
-- diff windows hang or segfault nvim. Panes are labeled via winbar instead.
local function scratch_buf(lines, ft)
  local b = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.bo[b].bufhidden = "wipe"
  vim.bo[b].modifiable = false
  vim.bo[b].filetype = ft
  return b
end

-- Flag conflict regions in the result buffer: `!` sign on each line, a hint at
-- the end of the first line. ns_start marks only the first line (for ]n / [n).
local function mark_conflicts(buf, conflicts)
  local last = vim.api.nvim_buf_line_count(buf) - 1
  for _, c in ipairs(conflicts) do
    local first = math.min(c.start, last)
    local hint = c.count == 0 and " conflict: both inserted here; gh yours / gl disk"
        or " conflict: original shown; gh yours / gl disk"
    vim.api.nvim_buf_set_extmark(buf, ns_start, first, 0, {
      virt_text = { { hint, "DiagnosticWarn" } }, virt_text_pos = "eol",
    })
    for row = first, math.min(c.start + math.max(c.count, 1) - 1, last) do
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { sign_text = "!", sign_hl_group = "DiagnosticWarn" })
    end
  end
end

local function jump_conflict(buf, dir)
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns_start, 0, -1, {})
  if dir < 0 then marks = vim.fn.reverse(marks) end
  for _, m in ipairs(marks) do
    if (dir > 0 and m[2] > row) or (dir < 0 and m[2] < row) then
      vim.api.nvim_win_set_cursor(0, { m[2] + 1, 0 })
      return
    end
  end
  notify(#marks == 0 and "No conflicts" or "No more conflicts this way")
end

-- Three-pane merge view in a new tab: YOURS | RESULT (real buffer) | DISK.
local function open_3way(buf, yours, disk, conflicts)
  local ft = vim.bo[buf].filetype
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
  local left = scratch_buf(yours, ft)
  local right = scratch_buf(disk, ft)

  -- split + win_set_buf rather than :sbuffer, which 'switchbuf' (useopen,usetab)
  -- would redirect to an existing window instead of opening the new layout
  vim.cmd("tab split")
  local tab = vim.api.nvim_get_current_tabpage()
  local mid_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(mid_win, buf)
  vim.cmd("vertical leftabove split")
  local left_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(left_win, left)
  vim.api.nvim_set_current_win(mid_win)
  vim.cmd("vertical rightbelow split")
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_win, right)
  for _, b in ipairs({ buf, left, right }) do render_markdown(b, false) end
  -- 'linematch' (0.12 default) breaks :diffget across a 3-way diff: taking a
  -- hunk deletes lines instead (reproducible with --clean). 'diffopt' is
  -- global, so drop it while this view is open and restore it on close.
  local saved_diffopt = vim.o.diffopt
  vim.o.diffopt = saved_diffopt:gsub("linematch:%d+", ""):gsub(",,+", ","):gsub("^,", ""):gsub(",$", "")
  for _, w in ipairs({ left_win, mid_win, right_win }) do
    vim.api.nvim_win_call(w, function() vim.cmd.diffthis() end)
  end
  vim.wo[left_win].winbar = "%#DiffDelete# YOURS %* unsaved edits (read-only) · dp push"
  vim.wo[mid_win].winbar = "%#DiffText# RESULT %* " .. name .. " · gh yours · gl disk · ]n conflict · q close"
  vim.wo[right_win].winbar = "%#DiffAdd# DISK %* (read-only) · dp push"
  vim.cmd("wincmd =")

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_clear_namespace(buf, ns_start, 0, -1)
  mark_conflicts(buf, conflicts)

  local mid_maps = { { { "n", "x" }, "gh" }, { { "n", "x" }, "gl" }, { "n", "]n" }, { "n", "[n" }, { "n", "q" } }
  local closed = false
  -- Order matters: close the windows first (the side buffers are bufhidden=wipe
  -- so they go with them), only then delete leftovers. Deleting a buffer that
  -- is still shown in a diff window from inside a mapping segfaulted nvim.
  local function teardown()
    for _, m in ipairs(mid_maps) do pcall(vim.keymap.del, m[1], m[2], { buffer = buf }) end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      vim.api.nvim_buf_clear_namespace(buf, ns_start, 0, -1)
    end
    -- diff off in every pane before any window closes (belt and braces for the
    -- render-markdown crash noted at render_markdown())
    for _, w in ipairs({ left_win, mid_win, right_win }) do
      if vim.api.nvim_win_is_valid(w) then vim.api.nvim_win_call(w, function() vim.cmd.diffoff() end) end
    end
    if vim.api.nvim_win_is_valid(mid_win) then vim.wo[mid_win].winbar = "" end
    if vim.api.nvim_tabpage_is_valid(tab) and #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
    else
      for _, w in ipairs({ left_win, right_win }) do
        if vim.api.nvim_win_is_valid(w) then pcall(vim.api.nvim_win_close, w, true) end
      end
    end
    for _, b in ipairs({ left, right }) do
      if vim.api.nvim_buf_is_valid(b) then pcall(vim.api.nvim_buf_delete, b, { force = true }) end
    end
    render_markdown(buf, true) -- only after the diff windows are gone
    vim.o.diffopt = saved_diffopt
  end
  local function close()
    if closed then return end
    closed = true
    vim.schedule(teardown) -- run outside mapping/autocmd context
  end

  -- however the view goes away (q, :q on any pane, :tabclose), clean up fully
  for _, b in ipairs({ left, right }) do
    vim.api.nvim_create_autocmd("BufWipeout", { buffer = b, once = true, callback = close })
  end
  vim.api.nvim_create_autocmd("WinClosed", { pattern = tostring(mid_win), once = true, callback = close })

  local function map(modes, lhs, rhs, desc, b)
    vim.keymap.set(modes, lhs, rhs, { buffer = b, silent = true, desc = desc })
  end
  -- string rhs so visual mode passes the '<,'> range: take only the selected lines
  map({ "n", "x" }, "gh", ":diffget " .. left .. "<CR>", "Merge: take yours", buf)
  map({ "n", "x" }, "gl", ":diffget " .. right .. "<CR>", "Merge: take disk", buf)
  map("n", "]n", function() jump_conflict(buf, 1) end, "Merge: next conflict", buf)
  map("n", "[n", function() jump_conflict(buf, -1) end, "Merge: prev conflict", buf)
  map("n", "q", close, "Merge: close", buf)
  for _, b in ipairs({ left, right }) do
    map({ "n", "x" }, "dp", ":diffput " .. buf .. "<CR>", "Merge: push to result", b)
    map("n", "q", close, "Merge: close", b)
  end

  vim.api.nvim_set_current_win(mid_win)
  if #conflicts > 0 then
    vim.api.nvim_win_set_cursor(mid_win, { math.min(conflicts[1].start + 1, vim.api.nvim_buf_line_count(buf)), 0 })
  end
end

-- Two-pane read-only disk view next to the buffer (:FileDiff).
local function open_diff(buf, disk)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    vim.cmd.buffer(buf)
    win = vim.api.nvim_get_current_win()
  end
  vim.api.nvim_set_current_win(win)
  local scratch = scratch_buf(disk, vim.bo[buf].filetype)
  vim.cmd("vertical leftabove split")
  local scratch_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(scratch_win, scratch)
  vim.wo[scratch_win].winbar = "%#DiffAdd# DISK %* (read-only) · q close"
  render_markdown(buf, false)
  render_markdown(scratch, false)
  vim.cmd.diffthis()
  vim.api.nvim_win_call(win, function() vim.cmd.diffthis() end)

  -- `q` closes the split from either side; the buffer-local `q` on the real
  -- buffer is removed again however the split goes away (q, :close, :bd).
  -- Close the window (scratch is bufhidden=wipe) rather than deleting the
  -- buffer while it's displayed in diff mode, which crashed nvim.
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function() vim.cmd.diffoff() end)
    end
    pcall(vim.keymap.del, "n", "q", { buffer = buf })
    vim.schedule(function() render_markdown(buf, true) end)
  end
  vim.api.nvim_create_autocmd("BufWipeout", { buffer = scratch, once = true, callback = close })
  local function close_split()
    if vim.api.nvim_win_is_valid(scratch_win) then pcall(vim.api.nvim_win_close, scratch_win, true) end
  end
  vim.keymap.set("n", "q", close_split, { buffer = scratch, desc = "Close disk diff" })
  vim.keymap.set("n", "q", close_split, { buffer = buf, desc = "Close disk diff" })

  vim.api.nvim_set_current_win(win)
end

local function target(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not is_file_buf(buf) then
    notify("Not a file buffer", vim.log.levels.WARN)
    return nil
  end
  local disk = read_lines(vim.api.nvim_buf_get_name(buf), buf)
  if not disk then
    notify("File doesn't exist on disk; :w to write it", vim.log.levels.WARN)
    return nil
  end
  return buf, disk
end

M.diff = function(buf)
  local b, disk = target(buf)
  if not b then return end
  local ours = vim.api.nvim_buf_get_lines(b, 0, -1, false)
  if vim.deep_equal(ours, disk) then
    notify("Buffer matches disk")
    return
  end
  if vim.bo[b].modified then apply(b, ours) end -- sync mtime so :w won't prompt
  open_diff(b, disk)
end

M.merge = function(buf)
  local b, disk = target(buf)
  if not b then return end
  local ours = vim.api.nvim_buf_get_lines(b, 0, -1, false)
  if vim.deep_equal(ours, disk) then
    notify("Buffer matches disk")
    bases[b] = disk
    return
  end

  local base = bases[b]
  if base and vim.deep_equal(base, disk) then
    notify("Disk unchanged since you loaded/saved; nothing to merge. :FileDiff to compare")
    return
  end

  local result, err
  if base then
    result, err = merge3(ours, base, disk)
    if not result then
      notify("git merge-file failed: " .. tostring(err) .. "\nResult starts as your version", vim.log.levels.ERROR)
    end
  else
    notify("No snapshot from when this file was loaded, so no auto-merge.\n"
      .. "Result starts as your version; pull from disk with gl", vim.log.levels.WARN)
  end

  -- :e! inside apply also records disk as the new base
  apply(b, result and result.lines or ours)
  local conflicts = result and result.conflicts or {}
  open_3way(b, ours, disk, conflicts)

  if not result then return end
  if #conflicts == 0 then
    notify("Merged cleanly; review in the middle pane.\ngh/gl take yours/disk, q close, :w save, u undoes the merge")
  else
    notify(("%d conflict%s marked ! in the middle (original text shown there).\n"
      .. "gh yours, gl disk (visual: just those lines), or edit. ]n/[n conflicts, q close, :w save"):format(
      #conflicts, #conflicts == 1 and "" or "s"), vim.log.levels.WARN)
  end
end

M.setup = function()
  local group = vim.api.nvim_create_augroup("FileMergeBase", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "FileChangedShellPost" }, {
    group = group,
    callback = function(ev) record_base(ev.buf) end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      -- ignore `:w other/path` which doesn't change what this buffer is based on
      -- resolve() both: on macOS /tmp -> /private/tmp, so raw paths can differ
      if vim.fn.resolve(vim.fn.fnamemodify(ev.match, ":p")) == vim.fn.resolve(vim.api.nvim_buf_get_name(ev.buf)) then
        record_base(ev.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufFilePost" }, {
    group = group,
    callback = function(ev) bases[ev.buf] = nil end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified then record_base(buf) end
  end

  vim.api.nvim_create_user_command("FileMerge", function() M.merge() end,
    { desc = "3-way merge disk changes into buffer" })
  vim.api.nvim_create_user_command("FileDiff", function() M.diff() end,
    { desc = "Diff buffer against file on disk" })
end

return M
