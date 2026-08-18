----------------------- CODE REVIEW ------------------------
-- Typed, persistent review comments drawn over codediff.nvim's side-by-side
-- diff. `,crr` opens a review, `,cr*` adds comments, `,crl` lists them.
--
-- We own the comments. This used to wrap review.nvim (georgeguimaraes/review.nvim,
-- removed 2026-08-14): its path parser, file matching, sign priority, storage
-- location, user commands and type ordering were all overridden here, so the
-- plugin was carrying less weight than the workarounds around it. A comment is just
--
--     { file = <canonical path>, lnum, end_lnum, type = "ISSUE", text = "..." }
--
-- held in `state.list`, persisted per branch as JSON under `.git/`, and rendered
-- three ways:
--   * a gutter sign, priority 100 by default so it outranks gitsigns (6) and
--     marks (8) -- every line worth commenting on is a changed line, and losing
--     that fight is why comments used to look invisible;
--   * end-of-line virtual text, on the same extmark;
--   * the quickfix list, which is a VIEW regenerated from `state.list` on
--     demand. A `:grep` can no longer evict a review, it just means the view
--     gets rebuilt next time you open the list.
--
-- Why comments live on the RIGHT pane, and ONLY there
-- ---------------------------------------------------
-- codediff opens two panes per file:
--   left  = the git revision, a virtual `codediff:///<root>///<rev>/<path>`
--           buffer. codediff deliberately stops LSP from attaching there
--           (language servers crash on custom URI schemes), so `gd`/`K`/rename
--           do nothing on that side.
--   right = the real working-tree file -- an ordinary buffer with full LSP.
-- So you review on the right, where jumping to a definition that lives outside
-- the diff still works and `<C-o>` brings you back.
--
-- The left pane is the file at ANOTHER REVISION, so its line numbers are not the
-- file's: five lines added at the top means left line 6 is right line 11. A
-- comment anchored to the cursor there would be filed against the wrong
-- working-tree line, and a working-tree comment drawn there would sit on
-- unrelated old code. Translating through codediff's hunk map would fix both,
-- but the honest, cheap answer is that the revision pane is for reading: it gets
-- no signs, and its `,cr*` keys say so instead of recording a wrong line.

local M = {}

local TITLE = "Code Review Comments"

-- Ordered, so the type picker and the cheatsheet stay in step.
local TYPES = { "issue", "suggestion", "note", "praise", "question", "insight" }

-- { emoji, ascii, highlight, quickfix type, `,cr_` key, description }. Sign text
-- must be 1-2 display cells; the emoji are width 2 and the ASCII forms are too.
local TYPE_DEFS = {
  issue      = { "⚠ ", "!!", "DiagnosticError", "E", "i", "Problems to fix" },
  suggestion = { "💭", "->", "DiagnosticWarn", "W", "s", "Improvements" },
  note       = { "📝", "//", "DiagnosticInfo", "I", "n", "Observations" },
  praise     = { "✨", "++", "DiagnosticHint", "N", "p", "Positive feedback" },
  question   = { "? ", "??", "DiagnosticInfo", "I", "q", "Clarification needed" },
  insight    = { "💡", "*>", "DiagnosticHint", "N", "k", "Useful observations" },
}

--- Presentation for a comment type. SimpleUI terminals get the ASCII markers.
local function def(kind)
  local d = TYPE_DEFS[tostring(kind):lower()] or TYPE_DEFS.note
  return { sign = SimpleUI and d[2] or d[1], hl = d[3], qf = d[4], key = d[5], desc = d[6] }
end

local ns = vim.api.nvim_create_namespace("pwnvim_review")

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Review" })
end

--- Comment text is multi-line; signs, virtual text and quickfix entries are not.
local function oneline(text)
  return (vim.trim(text):gsub("%s*\n%s*", " / "))
end

----------------------------------------------------------------------
-- Paths: one spelling per file, everywhere
----------------------------------------------------------------------

--- `fnamemodify(':p')` does NOT resolve symlinks, so `/tmp/x` (what the working
--- tree pane reports) and `/private/tmp/x` (what codediff resolves to) compared
--- unequal and commenting from one pane wiped the other pane's signs.
local function canonical(path)
  if not path or path == "" then
    return ""
  end
  return vim.fs.normalize(vim.fn.resolve(vim.fn.fnamemodify(path, ":p")))
end

--- The real working-tree path behind a `codediff://` buffer name, or nil.
--- codediff 2.53 names revision buffers `codediff:///<root>///<rev>/<path>`;
--- use codediff's own parser rather than guessing at that format.
local function codediff_path(name)
  if not name or not name:match("^codediff://") then
    return nil
  end
  local ok_vf, vf = pcall(require, "codediff.core.virtual_file")
  if not ok_vf then
    return nil
  end
  local ok, root, _, rel = pcall(vf.parse_url, name)
  if ok and root and rel then
    return canonical(root .. "/" .. rel)
  end
  return nil
end

--- The real file a buffer shows, whichever pane it is.
local function buf_file(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  return codediff_path(name) or canonical(name)
end

--- The left pane: the file at some other revision. Its line numbers are that
--- revision's, not the working tree's -- see the header.
local function is_revision(buf)
  return vim.api.nvim_buf_get_name(buf or 0):match("^codediff://") ~= nil
end

--- codediff's explorer is a listing, not a file: a comment added there would
--- anchor to the explorer buffer's name.
local function is_explorer(buf)
  return vim.bo[buf or 0].filetype == "codediff-explorer"
      or vim.api.nvim_buf_get_name(buf or 0):match("CodeDiff Explorer") ~= nil
end

--- The working-tree file this buffer is, or "" if it is not one. The only
--- surface review comments attach to, render on, or are read from.
local function review_file(buf)
  if is_revision(buf) or is_explorer(buf) then
    return ""
  end
  return buf_file(buf)
end

----------------------------------------------------------------------
-- The model: a list of comments, persisted per branch
----------------------------------------------------------------------

local state = { list = nil, file = nil }

--- A branch name as a filename. Flattening is lossy -- `feat/login` and
--- `feat-login` are different branches that both spell `feat-login` -- so
--- anything that had to be rewritten carries a digest of the original. Names
--- that need no rewriting (the overwhelming majority) keep their plain spelling.
local function slug(name)
  local s = (name:gsub("[^%w%-_]", "-"))
  if s == name and s ~= "" then
    return s
  end
  return (s ~= "" and s or "unknown") .. "-" .. vim.fn.sha256(name):sub(1, 8)
end

--- The `.git` directory for the cwd, or nil outside a repo. In a linked worktree
--- or a submodule `.git` is a *file* pointing at the real gitdir -- follow it, so
--- each worktree keeps its own reviews instead of sharing the main checkout's.
local function gitdir()
  local found = vim.fs.find(".git", { upward = true, path = vim.uv.cwd() or ".", limit = 1 })
  local dot = found[1]
  if not dot then
    return nil
  end
  local stat = vim.uv.fs_stat(dot)
  if stat and stat.type == "directory" then
    return vim.fs.normalize(dot)
  end
  local f = io.open(dot, "r")
  if not f then
    return nil
  end
  local line = f:read("*l") or ""
  f:close()
  local path = line:match("^gitdir:%s*(.-)%s*$")
  if not path or path == "" then
    return nil
  end
  if not path:match("^/") then -- gitdir: is relative to the dir holding the file
    path = vim.fs.dirname(dot) .. "/" .. path
  end
  return vim.fs.normalize(path)
end

--- The current branch, read straight out of `.git/HEAD` rather than shelling out
--- to `git` on every save. Detached HEAD has no branch name, so key those reviews
--- off the short SHA -- still stable for as long as you sit on that commit.
local function branch(dir)
  local f = io.open(dir .. "/HEAD", "r")
  if not f then
    return "unknown"
  end
  local head = vim.trim(f:read("*l") or "")
  f:close()
  local ref = head:match("^ref:%s*refs/heads/(.+)$")
  if ref then
    return ref
  end
  return head:match("^%x%x%x%x%x%x%x") and ("detached-" .. head:sub(1, 7)) or "unknown"
end

--- Reviews are per branch and live inside `.git/`, which makes them local by
--- construction: git never tracks its own directory, so there is no .gitignore
--- entry to keep correct, nothing in `git status`, and no chance of a half-written
--- review riding along on a commit. Reviewing a branch is what you do, so the
--- branch is what the comments belong to -- switch branches, get that branch's
--- review back. Outside a repo there is no such place, so fall back to the shared
--- data dir keyed by cwd.
---
--- Every `mkdir` here is guarded. This is reached from the render path, which
--- runs on every window event, and `vim.fn.mkdir` THROWS (E739) rather than
--- returning an error -- on a read-only checkout or a restrictive `.git` that
--- turned into an error message on every keystroke.
local function store_path()
  local data = vim.fn.stdpath("data") .. "/review"
  local dir = gitdir()
  local name
  if dir then
    local reviews = dir .. "/pwnvim-review"
    name = slug(branch(dir))
    if pcall(vim.fn.mkdir, reviews, "p") then
      return string.format("%s/%s.json", reviews, name)
    end
    -- `.git` is not writable. Keep the per-branch scoping, just keep it
    -- elsewhere; the gitdir digest is what keeps two repos sitting on the same
    -- branch name apart.
    name = string.format("%s-%s-%s", slug(vim.fn.fnamemodify(dir, ":h:t")), vim.fn.sha256(dir):sub(1, 12), name)
  else
    local cwd = vim.uv.cwd() or "."
    name = string.format("%s-%s", slug(vim.fn.fnamemodify(cwd, ":t")), vim.fn.sha256(cwd):sub(1, 12))
  end
  pcall(vim.fn.mkdir, data, "p")
  return string.format("%s/%s.json", data, name)
end

--- Point `state` at the current branch's file, dropping an in-memory list that
--- belongs to a different branch (or a different repo, if the session moved).
---
--- Called from the entry points a user reaches deliberately -- opening a review,
--- acting on a comment, listing, exporting -- and NOT from the render path, which
--- runs on every window event and would turn each keystroke into a stat of
--- `.git/HEAD`. So after a `git checkout` in another terminal the signs still show
--- the old branch's comments until you touch a review command; any of them, or
--- `:ReviewRefresh`, puts it right.
local function rescope()
  if state.file and state.file ~= store_path() then
    state.list, state.file = nil, nil
  end
end

--- The comment list, loaded from disk on first use.
---
--- A file we cannot parse is NOT treated as an empty review: that would hand the
--- next `save()` a clean slate and overwrite the only copy of the comments with
--- `[]`. Set it aside as `.corrupt` instead, so the data survives and the next
--- save starts fresh; if even that fails, refuse to save at all rather than
--- destroy it.
local function comments()
  if not state.list then
    state.file = store_path()
    state.list = {}
    state.corrupt = nil
    local f = io.open(state.file, "r")
    if f then
      local ok_read, raw = pcall(f.read, f, "*a") -- read inside the pcall: it is
      f:close()                                   -- an argument, so a throw here
      local ok, data = false, nil                 -- would escape and leak `f`.
      if ok_read then
        ok, data = pcall(vim.json.decode, raw or "")
      end
      if ok and type(data) == "table" then
        state.list = data
      elseif vim.trim(raw or "") ~= "" then
        local bak = state.file .. ".corrupt"
        state.corrupt = not os.rename(state.file, bak) and state.file or nil
        notify(state.corrupt
          and ("Review file is unreadable and could not be set aside: " .. state.file .. " -- not saving")
          or ("Review file was unreadable; moved to " .. bak .. " and started a new one"),
          vim.log.levels.ERROR)
      end
    end
  end
  return state.list
end

--- Written after every change, so there is no save command to forget. `mark` is
--- a live extmark handle and never goes to disk.
---
--- Write-then-rename, because `io.open(path, "w")` truncates to zero bytes before
--- the first byte of the new content lands: a crash or a full disk inside that
--- window used to leave a half-written file, which reads back as no comments at
--- all. `rename` is atomic within a filesystem, and the temp file is a sibling so
--- it always is one. Failures are reported -- losing a review silently while the
--- comment sits there in the Trouble list looking saved is the worst outcome.
local function save()
  local list = comments() -- first: this is what sets `state.file` and `state.corrupt`
  if state.corrupt then
    notify("Review not saved: " .. state.corrupt .. " is unreadable and could not be set aside",
      vim.log.levels.ERROR)
    return
  end
  local out = {}
  for _, c in ipairs(list) do
    out[#out + 1] = { file = c.file, lnum = c.lnum, end_lnum = c.end_lnum, type = c.type, text = c.text }
  end
  local tmp = state.file .. ".tmp"
  local f, open_err = io.open(tmp, "w")
  if not f then
    notify("Review not saved: " .. (open_err or tmp), vim.log.levels.ERROR)
    return
  end
  -- Buffered writes surface their error at close, so both are checked.
  local wrote = f:write(vim.json.encode(out))
  local closed, close_err = f:close()
  if not wrote or not closed then
    os.remove(tmp)
    notify("Review not saved: " .. (close_err or "write failed"), vim.log.levels.ERROR)
    return
  end
  local moved, rename_err = os.rename(tmp, state.file)
  if not moved then
    os.remove(tmp)
    notify("Review not saved: " .. (rename_err or "rename failed"), vim.log.levels.ERROR)
  end
end

--- Re-anchor: read line numbers back out of the extmarks, which drift with the
--- edits above them while the working-tree buffer is open. Cheap robustness --
--- there is no anchoring by content, so a comment on a file edited outside this
--- session keeps the line number it was written with.
---
--- Both ends move independently. A range comment carries a second, invisible
--- extmark on its last line, so inserting INSIDE the range grows it instead of
--- sliding it: a `10-20` comment with five lines added at 13 becomes `10-25`,
--- which is still the same code. Shifting `end_lnum` by the start's delta (what
--- this used to do) left the tail behind.
--- @return boolean anything moved
local function sync()
  local moved = false
  for _, c in ipairs(comments()) do
    local m = c.mark
    if m and vim.api.nvim_buf_is_valid(m.buf) then
      local pos = vim.api.nvim_buf_get_extmark_by_id(m.buf, ns, m.id, {})
      if pos and pos[1] then
        local lnum = pos[1] + 1
        local last = c.end_lnum or c.lnum
        local fin = lnum + (last - c.lnum) -- no end mark: carry the width along
        if m.id_end then
          local e = vim.api.nvim_buf_get_extmark_by_id(m.buf, ns, m.id_end, {})
          if e and e[1] then
            fin = e[1] + 1
          end
        end
        fin = math.max(fin, lnum)
        if lnum ~= c.lnum or fin ~= last then
          c.lnum, c.end_lnum = lnum, fin
          moved = true
        end
      end
    end
  end
  return moved
end

----------------------------------------------------------------------
-- Rendering: signs + virtual text + the quickfix view
----------------------------------------------------------------------

--- `DiagnosticError` -> `DiagnosticVirtualTextError` when the theme defines it.
--- Both catppuccin and onedark do; SimpleUI/ir_black may not, hence the check.
local function virt_hl(hl)
  local candidate = hl:gsub("^Diagnostic", "DiagnosticVirtualText")
  local ok, d = pcall(vim.api.nvim_get_hl, 0, { name = candidate })
  return (ok and d and next(d) ~= nil) and candidate or hl
end

--- Truncate to `width` SCREEN CELLS. Everything here has to be measured in cells,
--- not bytes or characters: `#"…"` is 3 bytes for a 1-cell glyph, and emoji and
--- CJK are 1 character but 2 cells. Comment text is prose and routinely has both.
local function truncate(s, width)
  if vim.fn.strdisplaywidth(s) <= width then
    return s
  end
  local dots = SimpleUI and "..." or "…"
  local budget = math.max(0, width - vim.fn.strdisplaywidth(dots))
  -- Cells >= chars, so `budget` chars is an upper bound for a `budget`-cell fit;
  -- walk down from there, which is one or two steps unless the text is all wide.
  local n = math.min(vim.fn.strchars(s), budget)
  while n > 0 do
    local cut = vim.fn.strcharpart(s, 0, n)
    if vim.fn.strdisplaywidth(cut) <= budget then
      return cut .. dots
    end
    n = n - 1
  end
  return dots
end

--- One extmark per comment carries both halves of the rendering: the gutter
--- sign and the end-of-line virtual text.
local function render_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  -- Every mark in this buffer is now gone, so drop the handles BEFORE re-issuing
  -- any. `clear_namespace` restarts the extmark id allocator at 1, so the ids we
  -- just destroyed are about to be handed out again -- and a comment that keeps a
  -- stale one (any comment skipped by the loop below, e.g. because the buffer
  -- shrank past its line) would have `sync()` read a *different* comment's
  -- position out of it and silently re-anchor itself onto that comment's line.
  for _, c in ipairs(comments()) do
    if c.mark and c.mark.buf == buf then
      c.mark = nil
    end
  end
  -- Working-tree buffers only: the revision pane's line numbers belong to another
  -- revision, so a sign placed there by `c.lnum` lands on unrelated code.
  local file = review_file(buf)
  if file == "" then
    return
  end
  local prio = tonumber(vim.g.pwnvim_review_sign_priority) or 100
  local width = tonumber(vim.g.pwnvim_review_virt_width) or 60
  local last = vim.api.nvim_buf_line_count(buf)
  for _, c in ipairs(comments()) do
    if c.file == file and c.lnum >= 1 and c.lnum <= last then
      local d = def(c.type)
      local opts = { sign_text = d.sign, sign_hl_group = d.hl, priority = prio }
      if vim.g.pwnvim_review_virt_text ~= false then
        local label = string.format("  %s %s: %s", vim.trim(d.sign), c.type, oneline(c.text))
        opts.virt_text = { { truncate(label, width), virt_hl(d.hl) } }
        opts.virt_text_pos = "eol"
        opts.hl_mode = "combine"
      end
      local ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, ns, c.lnum - 1, 0, opts)
      if ok then
        c.mark = { buf = buf, id = id }
        -- A second, invisible mark on the last line, so an edit inside the range
        -- grows it rather than moving it. Skipped when the range is one line or
        -- its tail is past the end of the buffer.
        local fin = c.end_lnum or c.lnum
        if fin > c.lnum and fin <= last then
          local ok_end, id_end = pcall(vim.api.nvim_buf_set_extmark, buf, ns, fin - 1, 0, {})
          if ok_end then
            c.mark.id_end = id_end
          end
        end
      end
    end
  end
end

local function qf_items()
  local items = {}
  for _, c in ipairs(comments()) do
    items[#items + 1] = {
      filename = c.file,
      lnum = c.lnum,
      end_lnum = c.end_lnum or c.lnum,
      col = 1,
      type = def(c.type).qf,
      text = string.format("[%s] %s", c.type, oneline(c.text)),
    }
  end
  return items
end

--- Rebuild the quickfix view. Replaces in place when the review list is already
--- current; `force` (i.e. someone asked to see the list) pushes a fresh list
--- instead, so a `:grep` that took the quickfix over is stepped past rather
--- than fought with.
local function sync_qf(force)
  local current = vim.fn.getqflist({ title = 1 }).title == TITLE
  if not (current or force) then
    return
  end
  vim.fn.setqflist({}, current and "r" or " ", { items = qf_items(), title = TITLE })
  pcall(function()
    require("trouble").refresh("qflist")
  end)
end

--- Re-anchor, redraw every loaded buffer, update the list view if it is showing.
local function refresh()
  sync()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      render_buf(buf)
    end
  end
  sync_qf(false)
end

--- Every mutation ends here: redraw, then persist.
local function commit()
  refresh()
  save()
end

--- Show all comments. Trouble rather than the snacks picker: this is a panel
--- you keep open beside the diff and read down. The snacks picker is a modal
--- fuzzy-finder that closes on selection -- right for "jump to one of many",
--- wrong for "show me my review". `,qQ` still opens the snacks qflist picker.
--- @param opts table|nil { focus = boolean }
function M.open_list(opts)
  rescope()
  if #comments() == 0 then
    notify("No review comments yet")
    return
  end
  sync()
  sync_qf(true)
  local focus = not (opts and opts.focus == false)
  if not pcall(vim.cmd, string.format("Trouble qflist open focus=%s", focus)) then
    vim.cmd("copen")
  end
end

--- On by default: the list opens itself, without stealing the cursor, whenever
--- a comment is added. `vim.g.pwnvim_review_autolist = false` turns it off.
local function autolist()
  if vim.g.pwnvim_review_autolist == false then
    return
  end
  vim.schedule(function()
    M.open_list({ focus = false })
  end)
end

----------------------------------------------------------------------
-- Multi-line comment input
----------------------------------------------------------------------

--- A scratch float, used by both add and edit. `vim.ui.input` (dressing) and
--- snacks.input are single-line prompts; review comments are prose and are
--- routinely longer than a cmdline.
local function input(title, default, on_submit)
  local lines = vim.split(default or "", "\n", { plain = true })
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.min(80, math.max(40, math.floor(vim.o.columns * 0.7)))
  local height = math.max(4, math.min(12, #lines + 1))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = SimpleUI and "single" or "rounded",
    title = " " .. title .. " ",
    footer = " <C-s> or <CR> in normal mode: save   q or <C-c>: cancel ",
  })
  vim.wo[win].wrap = true

  local done = false
  local function finish(submit)
    if done then
      return
    end
    done = true
    -- Without this, submitting with <C-s> from insert mode closes the float and
    -- leaves the buffer underneath in insert mode -- the next keys you type go
    -- into the file you were reviewing.
    vim.cmd("stopinsert")
    local text = submit and vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")) or ""
    pcall(vim.api.nvim_win_close, win, true)
    -- Cancelling is a no-op; submitting always calls back, empty text included,
    -- because "delete every line and save" means different things to a new
    -- comment and to an edit of one that already exists.
    if submit then
      on_submit(text)
    end
  end

  vim.keymap.set({ "n", "i" }, "<C-s>", function() finish(true) end, { buffer = buf })
  vim.keymap.set("n", "<CR>", function() finish(true) end, { buffer = buf })
  vim.keymap.set("n", "q", function() finish(false) end, { buffer = buf })
  vim.keymap.set({ "n", "i" }, "<C-c>", function() finish(false) end, { buffer = buf })
  -- `:q`, a click elsewhere, anything: closing the window cancels.
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function() finish(false) end,
  })

  vim.cmd("normal! G$")
  if not default or default == "" then
    -- Scheduled: `startinsert` is dropped if the window was opened from inside
    -- a keymap that is still executing typeahead.
    vim.schedule(function()
      if vim.api.nvim_get_current_win() == win then
        vim.cmd("startinsert!")
      end
    end)
  end
end

----------------------------------------------------------------------
-- Comment actions
----------------------------------------------------------------------

--- What is being commented on: the visual selection, or the cursor line.
--- Captured eagerly because both the type picker and the input float are async
--- and the selection is long gone by the time they call back.
local function target(visual)
  rescope()
  sync()
  local a, b = vim.fn.line("."), vim.fn.line(".")
  if visual then
    a, b = vim.fn.line("v"), vim.fn.line(".")
    if a > b then
      a, b = b, a
    end
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end
  return { file = review_file(0), lnum = a, end_lnum = b }
end

local function covering(at)
  local out = {}
  for i, c in ipairs(comments()) do
    if c.file == at.file and c.lnum <= at.end_lnum and (c.end_lnum or c.lnum) >= at.lnum then
      out[#out + 1] = { index = i, comment = c }
    end
  end
  return out
end

local function add(kind, at)
  if at.file == "" then
    notify("Not a file buffer", vim.log.levels.WARN)
    return
  end
  input(kind .. " comment", nil, function(text)
    if text == "" then
      notify("Empty comment, nothing added")
      return
    end
    table.insert(comments(), {
      file = at.file,
      lnum = at.lnum,
      end_lnum = at.end_lnum,
      type = kind,
      text = text,
    })
    commit()
    autolist()
  end)
end

local function del(at)
  local hits = covering(at)
  if #hits == 0 then
    notify("No review comment here", vim.log.levels.WARN)
    return
  end
  for i = #hits, 1, -1 do
    table.remove(state.list, hits[i].index)
  end
  commit()
  notify(string.format("Deleted %d comment%s", #hits, #hits == 1 and "" or "s"))
end

local function edit(at)
  local hits = covering(at)
  if #hits == 0 then
    notify("No review comment here", vim.log.levels.WARN)
    return
  end
  local c = hits[1].comment
  input("Edit " .. c.type, c.text, function(text)
    if text == "" then
      -- Emptying the float used to close it and silently keep the old text.
      -- Deleting on a blank save would be a surprising way to lose a comment,
      -- so say what happened and name the key that does it.
      notify("Comment left unchanged -- an empty edit deletes nothing; use ,crd to delete", vim.log.levels.WARN)
      return
    end
    c.text = text
    commit()
  end)
end

local function view(at)
  local hits = covering(at)
  if #hits == 0 then
    notify("No review comment here", vim.log.levels.WARN)
    return
  end
  local out = {}
  for _, h in ipairs(hits) do
    out[#out + 1] = string.format("[%s] %s", h.comment.type, h.comment.text)
  end
  notify(table.concat(out, "\n\n"))
end

--- `,crc`: no untyped comments, so ask which type first.
local function pick_type(at)
  vim.ui.select(TYPES, {
    prompt = "Review comment type:",
    format_item = function(t)
      local d = def(t)
      return string.format("%s %s - %s", d.sign, t:upper(), d.desc)
    end,
  }, function(choice)
    if choice then
      add(choice:upper(), at)
    end
  end)
end

--- `]r` / `[r`: next / previous comment in this buffer.
local function jump(dir)
  local file, cur, best = review_file(0), vim.fn.line("."), nil
  for _, c in ipairs(comments()) do
    if c.file == file and ((dir > 0 and c.lnum > cur) or (dir < 0 and c.lnum < cur)) then
      if not best or (dir > 0 and c.lnum < best) or (dir < 0 and c.lnum > best) then
        best = c.lnum
      end
    end
  end
  if not best then
    notify("No " .. (dir > 0 and "next" or "previous") .. " comment")
    return
  end
  -- Clamped: a comment written before the file shrank still carries its old line
  -- number, and an out-of-range cursor is a hard error, not a no-op.
  local last = vim.api.nvim_buf_line_count(0)
  if best > last then
    notify(string.format("Comment is at line %d, past the end of the file (%d lines)", best, last),
      vim.log.levels.WARN)
  end
  vim.api.nvim_win_set_cursor(0, { math.min(best, last), 0 })
end

----------------------------------------------------------------------
-- Export
----------------------------------------------------------------------

--- Markdown, as lines. Body text goes on indented continuation lines so
--- multi-line comments stay inside their list item.
local function markdown()
  local lines = { "# Code Review", "" }
  for i, c in ipairs(comments()) do
    local where = vim.fn.fnamemodify(c.file, ":.") .. ":" .. c.lnum
    if c.end_lnum and c.end_lnum > c.lnum then
      where = where .. "-" .. c.end_lnum
    end
    lines[#lines + 1] = string.format("%d. **[%s]** `%s`", i, c.type, where)
    for _, l in ipairs(vim.split(c.text, "\n", { plain = true })) do
      lines[#lines + 1] = "   " .. l
    end
    lines[#lines + 1] = ""
  end
  return lines
end

--- `,crm`: the whole review on the clipboard as markdown.
function M.to_clipboard()
  rescope()
  if #comments() == 0 then
    notify("No review comments to export", vim.log.levels.WARN)
    return
  end
  sync()
  vim.fn.setreg("+", table.concat(markdown(), "\n"))
  notify(string.format("Review copied to clipboard (%d comments)", #state.list))
end

--- `,crS`: hand the review to the sidekick AI CLI.
function M.to_sidekick()
  rescope()
  if #comments() == 0 then
    notify("No review comments to send", vim.log.levels.WARN)
    return
  end
  sync()
  local ok, cli = pcall(require, "sidekick.cli")
  if not ok then
    notify("sidekick.nvim is not available", vim.log.levels.ERROR)
    return
  end
  -- Pre-rendered `text`, never `msg`: sidekick expands `{...}` in a msg as
  -- context placeholders and discards the ENTIRE message if one is unknown,
  -- which any code snippet containing braces would trigger.
  cli.send({ text = vim.tbl_map(function(l) return { { l } } end, markdown()) })
end

----------------------------------------------------------------------
-- Keymaps
----------------------------------------------------------------------

-- Buffer-local review keys, under `,cr*` -- review's own room in the `,c`
-- AI/tooling family, next to `,ca` agentic, `,cc` codecompanion and `,cs`
-- sidekick. `,crr`, `,crl`, `,crm` and `,crS` are global instead: see
-- mappings.lua. { suffix, description, normal, visual }
local KEYS = {
  { "crc", "add comment (pick type)", function() pick_type(target(false)) end, function() pick_type(target(true)) end },
  { "crf", "add file-level comment", function()
    local at = target(false)
    at.lnum, at.end_lnum = 1, 1
    add("NOTE", at)
  end },
  { "crd", "delete comment",          function() del(target(false)) end,       function() del(target(true)) end },
  { "cre", "edit comment",            function() edit(target(false)) end },
  { "crv", "view comment on line",    function() view(target(false)) end },
}
for _, t in ipairs(TYPES) do -- ,cri ISSUE, ,crs SUGGESTION, ,crn NOTE, ...
  local kind = t:upper()
  KEYS[#KEYS + 1] = { "cr" .. def(t).key, "add " .. kind,
    function() add(kind, target(false)) end,
    function() add(kind, target(true)) end }
end

local function attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].pwnvim_review_maps or is_explorer(buf) then
    return
  end
  vim.b[buf].pwnvim_review_maps = true
  -- The revision pane gets the keys, but they explain themselves rather than
  -- recording a comment against a line number from a different revision. Leaving
  -- them unmapped would be a silent no-op, which reads as a broken keybinding.
  if is_revision(buf) then
    local wrong_pane = function()
      notify("This pane is the old revision -- its line numbers are not the file's. "
        .. "Comment from the working-tree pane on the right.", vim.log.levels.WARN)
    end
    for _, k in ipairs(KEYS) do
      vim.keymap.set({ "n", "v" }, "<leader>" .. k[1], wrong_pane,
        { buffer = buf, desc = "Review: " .. k[2] .. " (use the right-hand pane)" })
    end
    return
  end
  for _, k in ipairs(KEYS) do
    vim.keymap.set("n", "<leader>" .. k[1], k[3], { buffer = buf, desc = "Review: " .. k[2] })
    if k[4] then
      vim.keymap.set("v", "<leader>" .. k[1], k[4], { buffer = buf, desc = "Review: " .. k[2] })
    end
  end
  vim.keymap.set("n", "]r", function() jump(1) end, { buffer = buf, desc = "Review: next comment" })
  vim.keymap.set("n", "[r", function() jump(-1) end, { buffer = buf, desc = "Review: previous comment" })
end

--- `signcolumn=yes` is ONE column and the highest-priority sign wins it. Review
--- signs outrank gitsigns, so without this the git hunk marker would simply lose
--- instead -- widen to two so both are visible. Fixed width rather than `auto`
--- so the two diff panes keep the same gutter and stay aligned.
---
--- Deferred, and re-applied on every window entry: the working-tree file is
--- usually open in an ordinary window elsewhere too, and Neovim restores that
--- window's saved per-(window, buffer) options *after* WinEnter returns. A
--- synchronous set inside the autocmd is discarded; a scheduled one sticks.
--- Measured, not guessed.
local function widen_signcolumn(win)
  local want = vim.g.pwnvim_review_signcolumn
  if want == false then
    return
  end
  local value = type(want) == "string" and want or "yes:2"
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "codediff-explorer" then
      return
    end
    if vim.wo[win].signcolumn ~= value then
      pcall(vim.api.nvim_set_option_value, "signcolumn", value, { win = win, scope = "local" })
    end
  end)
end

--- Everything one window of a review tab needs. Idempotent, so it is safe to
--- call from every window/buffer event.
---
--- `sync()` first, and not optionally: `render_buf` destroys the extmarks and
--- rebuilds them from `c.lnum`, so any drift not yet read back out of the marks
--- is lost. This runs on every window event, which made that the common case --
--- comment a line, add a function above it, switch panes once, and the comment
--- silently snapped back onto the wrong code. `refresh()` already syncs; this is
--- the other path in.
local function outfit(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  sync()
  local buf = vim.api.nvim_win_get_buf(win)
  attach(buf)
  widen_signcolumn(win)
  render_buf(buf)
end

--- codediff builds the explorer first and loads the file panes afterwards, and
--- how much later depends on repo size and startup timing. A single pass on
--- CodeDiffOpen can therefore see ONLY the explorer and leave the panes with no
--- review keys at all -- timing-dependent enough to look random. Retry a few
--- times and let the window events below self-heal the rest.
--- Only the newest set of retries matters, so tabbing through the explorer stops
--- the previous file's pending passes instead of stacking a fresh four on top of
--- them -- twenty files used to leave eighty timers queued.
local retries = {}

local function attach_tab()
  local function pass()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      outfit(win)
    end
  end
  pass()
  for _, t in ipairs(retries) do
    pcall(function() t:stop() end)
  end
  retries = {}
  for _, delay in ipairs({ 50, 150, 400, 1000 }) do
    retries[#retries + 1] = vim.defer_fn(function()
      if vim.t.pwnvim_review == 1 then
        pass()
      end
    end, delay)
  end
end

-- Set by M.open() and consumed by the next CodeDiffOpen. codediff creates its
-- tab asynchronously -- `vim.cmd("CodeDiff")` returns while you are still on the
-- old tab -- so the review flag has to be set from the event, which fires with
-- the diff tab current. Marking the tab from M.open() would flag the wrong one.
local arm_review = false
local autocmds_done = false

local function ensure_autocmds()
  if autocmds_done then
    return
  end
  autocmds_done = true
  local grp = vim.api.nvim_create_augroup("PwnvimReview", { clear = true })

  -- All of these, deliberately. BufWinEnter alone misses stepping back into an
  -- already-displayed window (which is also when signcolumn gets restored), and
  -- opening a fresh file inside a review tab -- `,ld` into a file outside the
  -- diff -- was observed to reach FileType/BufReadPost but not Buf*Enter.
  -- Between them the tab repairs itself whenever the cursor lands in a window,
  -- necessarily before the user can type a review key.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "BufEnter", "BufReadPost", "FileType" }, {
    group = grp,
    callback = function()
      if vim.t.pwnvim_review == 1 then
        outfit(vim.api.nvim_get_current_win())
      end
    end,
  })

  -- Writing a file is what makes its new line numbers real, so that is when a
  -- comment that drifted with the edits above it has to be written back.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = grp,
    callback = function()
      if sync() then
        save()
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = grp,
    pattern = { "CodeDiffOpen", "CodeDiffFileSelect" },
    callback = function(ev)
      if ev.match == "CodeDiffOpen" and arm_review then
        arm_review = false
        vim.t.pwnvim_review = 1
        if #comments() > 0 then
          autolist() -- reopening a review with comments already in it
        end
      end
      if vim.t.pwnvim_review == 1 then
        vim.schedule(attach_tab)
      end
    end,
  })
end

----------------------------------------------------------------------
-- Entry points
----------------------------------------------------------------------

--- Open the review flow: codediff plus review annotations.
--- @param args string|nil extra arguments forwarded to :CodeDiff
function M.open(args)
  rescope()
  ensure_autocmds()
  arm_review = true
  local ok, err = pcall(vim.cmd, args and args ~= "" and ("CodeDiff " .. args) or "CodeDiff")
  if not ok then
    arm_review = false
    notify(type(err) == "string" and err or "CodeDiff failed", vim.log.levels.ERROR)
    return
  end
  -- Disarm on a timer as well. `:CodeDiff` reports "no changes to show" -- and
  -- toggles an existing diff tab CLOSED -- without raising an error and without
  -- ever firing CodeDiffOpen, which used to leave the flag set so that the next
  -- plain `:CodeDiff`, whenever it came, silently became a review. One second is
  -- far longer than codediff takes to open its tab and far shorter than the gap
  -- to a deliberate later `:CodeDiff`.
  vim.defer_fn(function() arm_review = false end, 1000)
end

function M.init()
  vim.api.nvim_create_user_command("Review", function(o) M.open(o.args) end, {
    nargs = "*",
    desc = "Open code review (codediff + review comments)",
  })
  local cmds = {
    ReviewList = { function() M.open_list() end, "Show all review comments in Trouble" },
    ReviewSidekick = { function() M.to_sidekick() end, "Send review comments to the sidekick AI CLI" },
    ReviewMarkdown = { function() M.to_clipboard() end, "Copy the review to the clipboard as markdown" },
    ReviewRefresh = { function()
      -- Genuinely re-read, which `rescope` alone does not do: it only reloads
      -- when the PATH changes, so a file rewritten under the same name -- by
      -- another Neovim, another worktree on the same branch, or an editor poking
      -- at the JSON -- was invisible until the next restart. Persist the drift we
      -- already know about first, so re-reading cannot throw it away.
      if state.list and sync() then
        save()
      end
      state.list, state.file = nil, nil
      refresh()
    end, "Re-read the current branch's comments from disk and redraw" },
    ReviewClear = { function()
      rescope()
      comments()
      state.list = {}
      commit()
      notify("Review cleared")
    end, "Delete every review comment on this branch" },
  }
  for name, c in pairs(cmds) do
    vim.api.nvim_create_user_command(name, c[1], { desc = c[2] })
  end
end

return M
