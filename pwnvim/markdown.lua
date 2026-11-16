local M = {}

M.mdFoldLevel = function(lnum)
  if not lnum then lnum = vim.v.lnum end
  local line = vim.fn.getline(lnum)
  local heading = string.match(line, "^#+ ")
  if heading then
    return ">" .. (string.len(heading) - 1) -- start off fold
  else
    return "="                              -- continue previous fold level
  end
end

M.setup = function(ev)
  -- local bufnr = vim.api.nvim_get_current_buf()
  local bufnr = ev.buf
  vim.g.joinspaces = true
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.spell = true
  vim.wo.list = false

  -- Treesitter is pretty good, but includes folds for bullet lists and code in code blocks
  -- which could be great, but more often annoys me. I'm not sure how to tune it, so
  -- just making my own function to collapse on headings instead
  -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.wo.foldexpr = "v:lua.require('pwnvim.markdown').mdFoldLevel(v:lnum)"
  vim.wo.foldenable = true
  vim.wo.foldlevel = 20
  vim.wo.foldcolumn = "auto:5"
  vim.wo.foldmethod = "expr"

  -- vim.bo.formatoptions = "jcroqln"
  vim.bo.formatoptions = 'jtqlnr' -- no c (insert comment char on wrap), with r (indent)
  vim.bo.comments = 'b:>,b:*,b:+,b:-'
  vim.bo.suffixesadd = '.md'

  --vim.bo.syntax = "off" -- we use treesitter exclusively on markdown now
  -- except temp off until https://github.com/MDeiml/tree-sitter-markdown/issues/114

  -- Make markdown-renderer link conventions resolve for gf; includeexpr is
  -- consulted when the name isn't found as-is (see M.resolveMdLink)
  vim.bo[ev.buf].includeexpr = "v:lua.require'pwnvim.markdown'.resolveMdLink(v:fname)"

  require('pwnvim.markdown').markdownsyntax()
  require('pwnvim.markdown').setupmappings(bufnr)

  vim.diagnostic.config({ virtual_lines = false }) -- no need to see this in markdown -- wavy underlines good enough

  -- no idea why the lua version of adding the command is failing
  -- vim.api.nvim_buf_add_user_command(0, 'PasteUrl', function(opts) require('pwnvim.markdown').pasteUrl() end, {})
  vim.cmd("command! PasteUrl lua require('pwnvim.markdown').pasteUrl()")

  -- Mail.app links only make sense where Mail.app and osascript exist
  if vim.fn.has('mac') == 1 then
    vim.cmd("command! PasteMailLinks lua require('pwnvim.markdown').pasteMailLinks()")
  end

  -- render-markdown setup is in plugins.lua M.notes(); just enable for this buffer
  if pcall(require, 'render-markdown') then
    require('render-markdown').buf_enable()
  end

  vim.cmd('packadd clipboard-image.nvim')
  -- note: PasteImg is just require'clipboard-image.paste'.paste_img()
  require 'clipboard-image'.setup {
    default = {
      img_name = function()
        vim.fn.inputsave()
        local name = vim.fn.input({ prompt = "Name: " })
        -- TODO: swap spaces out for dashes
        vim.fn.inputrestore()
        return os.date('%Y-%m-%d') .. "-" .. name
      end,
      img_dir = { "%:p:h", "%:t:r:s?$?_attachments?" },
      img_dir_txt = "%:t:r:s?$?_attachments?",
      -- TODO: can I put the name as the title somehow?
      affix = "![image](%s)"
    }
  }

  vim.cmd('packadd todo-comments.nvim')
  require("pwnvim.plugins.todo-comments") -- show todo's in markdown, too
  if require("todo-comments.config").options["highlight"] ~= nil then
    require("todo-comments.config").options.highlight.comments_only = false
  else
    require("todo-comments.config").options["highlight"] = {
      comments_only = false
    }
  end

  local autocmd = vim.api.nvim_create_autocmd
  local mdsave = vim.api.nvim_create_augroup("mdsave", { clear = true })
  -- markdown processors can optionally create smart quotes and stuff, but we want the source clean
  -- so spell check and other things work as expected
  autocmd("BufWritePre", {
    pattern = { "*.markdown", "*.md" },
    desc = "Remove smart quotes from markdown files",
    group = mdsave,
    callback = function()
      local curpos = vim.api.nvim_win_get_cursor(0)
      vim.cmd([[keeppatterns %s/[‘’′]/'/eg]])
      vim.cmd([[keeppatterns %s/[“”“”″]/"/eg]])
      vim.api.nvim_win_set_cursor(0, curpos)
    end
  })

  require('pwnvim.options').fourspaceindent()

  -- Force folds to be recalculated now. Our foldexpr is set just above, but when a buffer is
  -- opened by a picker/preview path rather than a plain :edit, the expr folds don't always get
  -- computed, leaving the file unfolded. This was originally a telescope bug workaround
  -- (nvim-telescope/telescope.nvim#559); telescope is gone but the failure mode is not
  -- telescope-specific -- snacks carries its own fold fixup for the same reason.
  -- Lousy side-effect: folds get calculated twice when opened normally.
  vim.cmd("normal zx")
end

-- mbr (https://github.com/zmre/mbr-markdown-browser) is not a pwnvim dependency:
-- bundling it pinned a second copy at whatever version this flake locked, which
-- then shadowed whatever the machine already had. Use the system one instead --
-- on macOS that also gets us the real MBR icon and Dock entry, since the system
-- build's `mbr` execs the binary inside MBR.app while a bare CLI build doesn't.
--
-- PATH alone isn't enough: launched from a GUI (pwneovide, Finder, Dock) macOS
-- gives us a stub PATH with none of the shell's additions, so probe the usual
-- install roots too.
local function mbrCandidates()
  local home = vim.env.HOME or vim.fn.expand("~")
  local candidates = {}
  local function add(path) candidates[#candidates + 1] = path end

  if vim.fn.has('mac') == 1 then
    add("/Applications/MBR.app/Contents/MacOS/mbr")          -- dmg / manual install
    add(home .. "/Applications/MBR.app/Contents/MacOS/mbr")  -- ditto, per-user
    add("/Applications/Nix Apps/MBR.app/Contents/MacOS/mbr") -- nix-darwin
    add(home .. "/Applications/Home Manager Apps/MBR.app/Contents/MacOS/mbr")
  end
  if vim.fn.isdirectory("/nix") == 1 then
    add("/run/current-system/sw/bin/mbr")                                -- NixOS / nix-darwin system profile
    add("/etc/profiles/per-user/" .. (vim.env.USER or "") .. "/bin/mbr") -- home-manager as a system module
    add(home .. "/.nix-profile/bin/mbr")
    add("/nix/var/nix/profiles/default/bin/mbr")
  end
  add(home .. "/.cargo/bin/mbr") -- cargo install --git https://github.com/zmre/mbr-markdown-browser
  add(home .. "/.local/bin/mbr")
  add("/opt/homebrew/bin/mbr")
  add("/usr/local/bin/mbr")
  add("/usr/bin/mbr")
  return candidates
end

-- Only successful lookups are cached, so installing mbr mid-session works.
local mbr_path = nil
M.findMbr = function()
  if mbr_path then return mbr_path end
  local found = vim.fn.exepath("mbr")
  if found == "" then
    for _, path in ipairs(mbrCandidates()) do
      if vim.fn.executable(path) == 1 then
        found = path
        break
      end
    end
  end
  if found == "" then return nil end
  mbr_path = found
  return found
end

M.openInMbr = function(path)
  local mbr = M.findMbr()
  if not mbr then
    vim.notify("mbr not found on PATH or in the usual install locations. See " ..
      "https://github.com/zmre/mbr-markdown-browser", vim.log.levels.WARN, { title = "MBR preview" })
    return
  end
  vim.fn.jobstart({ mbr, path or vim.fn.expand('%:p') }, { detach = true })
end

M.setupmappings = function(bufnr)
  -- normal mode mappings
  local mapnlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapn)
  local mapilocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapi)
  local mapvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapv)
  local mapnvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapnv)
  local mapnviclocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapnvic)

  mapnlocal("<leader>M", ':silent !open -a Marked\\ 2.app "%:p"<cr>', "Open Marked preview")
  mapnlocal("<leader>m", function()
    require('pwnvim.markdown').openInMbr()
  end, "Open MBR preview")

  mapnlocal("gl*", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]],
    "Add bullets")
  mapnlocal("gl>", [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]],
    "Add block quote")
  mapnlocal("gl[", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>5l]],
    "Add task")
  -- zk-aware gf: resolves [[wikilinks]], falls back to builtin gf
  mapnlocal("gf", require('pwnvim.markdown').followLink, "Go to link/file under cursor")
  mapnlocal("gt", require('pwnvim.markdown').transformUrlUnderCursorToMdLink, "Convert URL to link")
  mapnlocal("<leader>P", require('pwnvim.markdown').pasteUrl, "Paste URL as link")
  mapnlocal("<C-M-v>", require('pwnvim.markdown').pasteUrl, "Paste URL as link")
  if vim.fn.has('mac') == 1 then
    mapnlocal("<leader>nim", require('pwnvim.markdown').pasteMailLinks, "Insert links to selected Mail messages")
  end
  mapnlocal("<D-b>", 'ysiwe', "Bold")
  mapnlocal("<leader>b", 'ysiwe', "Bold")
  mapnlocal("<D-i>", 'ysiw_', "Italic")
  mapnlocal("<leader>i", 'ysiw_', "Italic")
  mapnlocal("<D-1>", 'ysiw`', "Code block")
  mapnlocal("<leader>`", 'ysiw`', "Code block")
  mapnlocal("<D-l>", 'ysiW]%a(`', "Link")

  -- insert mode mappings
  mapilocal("<C-M-v>", require('pwnvim.markdown').pasteUrl, "Paste URL as link")
  -- Replaces vim's builtin i_CTRL-P (keyword completion; blink covers that).
  -- If blink's menu is open, keep <C-p> as select-previous instead.
  mapilocal("<C-p>", function()
    local ok, blink = pcall(require, 'blink.cmp')
    if ok and blink.is_menu_visible() then
      blink.select_prev()
    else
      require('pwnvim.markdown').pasteUrl()
    end
  end, "Paste URL as link")
  mapilocal("<D-b>", "****<C-O>h", "Bold")
  mapilocal("<D-i>", [[__<C-O>h]], "Italic")
  mapilocal("<D-1>", [[``<C-O>h]], "Code block")
  -- override vim's builtin file completion, which completes from the (repo
  -- root) cwd; blink's repo_path does ./ from the file's dir and / from root
  mapilocal("<C-x><C-f>", function()
    require('blink.cmp').show({ providers = { 'repo_path' } })
  end, "Path completion (file dir / repo root)")

  mapilocal("<Tab>", require('pwnvim.markdown').indent, "Indent")
  mapilocal("<S-Tab>", require('pwnvim.markdown').outdent, "Outdent")

  -- The zk LSP has no textDocument/documentSymbol, so this can't rely on LSP symbols.
  -- outline.nvim's built-in markdown provider walks the headings without any LSP.
  mapnviclocal("<F7>", function() require("outline").toggle() end, "Show doc outline")

  -- visual mode mappings
  mapvlocal("gl*", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]],
    "Add bullets")
  mapvlocal("gl1", [[<cmd>let p=getcurpos('.')<cr>:s/^/0. /<cr>gv<C-v>0g<C-a>:call setpos('.', p)<cr>gv]],
    "Add ordered list")
  mapvlocal("gl>", [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]], "Add quotes")
  mapvlocal("gl[", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*)/\1* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]],
    "Add task")
  mapvlocal("gt", require('pwnvim.markdown').selectionToMdLink, "Convert URL to link")
  mapvlocal("<D-b>", "<Plug>(nvim-surround-visual)e", "Bold")
  mapvlocal("<leader>b", "<Plug>(nvim-surround-visual)e", "Bold")
  mapvlocal("<D-i>", "<Plug>(nvim-surround-visual)_", "Italic")
  mapvlocal("<leader>i", "<Plug>(nvim-surround-visual)_", "Italic")
  mapvlocal("<D-1>", "<Plug>(nvim-surround-visual)`", "Code ticks")
  mapvlocal("<leader>`", "<Plug>(nvim-surround-visual)_", "Code ticks")
  mapvlocal("<D-l>", "<Plug>(nvim-surround-visual)]%a(", "Code ticks")

  -- task shortcuts
  mapvlocal("<leader>ta", [[<cmd>grep "^\s*[*-] \[ \] "<cr>:Trouble quickfix<cr>]], "All tasks quickfix")
  mapnlocal("<leader>td", require("pwnvim.tasks").completeTaskDirect, "Task done")
  mapvlocal("<leader>td", ":luado return require('pwnvim.tasks').completeTask(line)", "Done")
  mapnlocal("<leader>tc", require("pwnvim.tasks").createTaskDirect, "Task create")
  mapnlocal("<leader>ts", require("pwnvim.tasks").scheduleTaskPrompt, "Task schedule")
  mapvlocal("<leader>ts", require("pwnvim.tasks").scheduleTaskBulk, "Schedule")
  mapnlocal("<leader>tt", require("pwnvim.tasks").scheduleTaskTodayDirect, "Task move today")
  mapvlocal("<leader>tt", ":luado return require('pwnvim.tasks').scheduleTaskToday(line)<cr>", "Today")

  -- Even when zk LSP doesn't connect, we can have formatters (including vale) give feedback -- ensure we have a way to see it
  mapnlocal("<leader>le", vim.diagnostic.open_float, "Show Line Diags")
end

M.markdownsyntax = function()
  vim.api.nvim_exec2([[
    let m = matchadd("bareLink", "\\<https:[a-zA-Z?&,;=$+%#/.!~':@0-9_-]*")
    " let m = matchadd("markdownCheckboxChecked", "[*-] \\[x\\] ")
    let m = matchadd("markdownCheckboxCanceled", "[*-] \\[-\\] .\\+")
    let m = matchadd("markdownCheckboxPostponed", "[*-] \\[>\\] .\\+")
    " below is because Noteplan uses capital X and default styling is a link on [X] so this will at least make it green
    let m = matchadd("@text.todo.checked", "[*-] \\[[xX]\\] .\\+")
    let m = matchadd("markdownTag", '#\w\+')
    let m = matchadd("markdownStrikethrough", "\\~\\~[^~]*\\~\\~")
    let m = matchadd("doneTag", '@done(20[^)]*)')
    let m = matchadd("highPrioTask", "[*-] \\[ \\] .\\+ !!! ")
    let m = matchadd("highPrioTask", "[*-] \\[ \\] .\\+ !!!$")
    let m = matchadd("medPrioTask", "[*-] \\[ \\] .\\+ !! ")
    let m = matchadd("medPrioTask", "[*-] \\[ \\] .\\+ !!$")
  ]], { output = false })
end

M.indent = function()
  local line = vim.api.nvim_get_current_line()
  local blink_ok, blink = pcall(require, 'blink.cmp')
  local menu_visible = blink_ok and blink.is_menu_visible()

  -- On bullet line and no completion menu visible - indent the line
  if line:match("^%s*[*-] ") and not menu_visible then
    local ctrlt = vim.api.nvim_replace_termcodes("<C-t>", true, false, true)
    vim.api.nvim_feedkeys(ctrlt, "n", false)
    return
  end

  -- Otherwise, let blink handle it (snippet navigation) or fallback to regular tab
  if blink_ok then
    if blink.snippet_active() then
      blink.snippet_forward()
    else
      vim.api.nvim_feedkeys("\t", "n", false)
    end
  else
    vim.api.nvim_feedkeys("\t", "n", false)
  end
end

M.outdent = function()
  local line = vim.api.nvim_get_current_line()
  local blink_ok, blink = pcall(require, 'blink.cmp')
  local menu_visible = blink_ok and blink.is_menu_visible()

  -- On bullet line and no completion menu visible - outdent the line
  if line:match("^%s*[*-] ") and not menu_visible then
    local ctrld = vim.api.nvim_replace_termcodes("<C-d>", true, false, true)
    vim.api.nvim_feedkeys(ctrld, "n", false)
    return
  end

  -- Otherwise, let blink handle snippet navigation or do nothing
  if blink_ok and blink.snippet_active() then
    blink.snippet_backward()
  end
end

-- Markdown gf override: follow the link under the cursor. Asks attached LSPs
-- (zk) for a definition first, which resolves [[wikilinks]] by title/id; if
-- none answer (no zk outside a notebook, or an unresolved link), falls back to
-- builtin gf (normal! so it can't recurse into this mapping).
M.followLink = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local function fallback()
    local ok, err = pcall(vim.cmd, "normal! gf")
    if not ok then
      vim.notify(tostring(err):gsub("^Vim%(normal%):", ""), vim.log.levels.WARN)
    end
  end
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/definition" })
  if #clients == 0 then return fallback() end
  local win = vim.api.nvim_get_current_win()
  local params = function(client)
    return vim.lsp.util.make_position_params(win, client.offset_encoding)
  end
  vim.lsp.buf_request_all(bufnr, "textDocument/definition", params, function(results)
    for client_id, res in pairs(results) do
      local loc = res.result
      -- result may be a single Location or a list of Location/LocationLink
      if loc and not loc.uri and not loc.targetUri then loc = loc[1] end
      if loc then
        local client = vim.lsp.get_client_by_id(client_id)
        vim.schedule(function()
          vim.lsp.util.show_document(loc, client and client.offset_encoding or "utf-16", { focus = true })
        end)
        return
      end
    end
    vim.schedule(fallback)
  end)
end

-- Project-root markers shared by gf link resolution below and the markdown
-- repo_path completion provider (plugins/completions.lua) — the two must
-- agree or completed root-absolute links won't resolve
M.root_markers = { '.zk', '.git', '.mbr', 'flake.nix', 'Cargo.toml', 'package.json' }

-- gf calls this (via includeexpr) when the name under the cursor isn't found
-- as-is. Markdown renderers accept link forms the filesystem doesn't:
-- repo-root-absolute paths, url-encoding (%20), omitted .md extensions,
-- trailing slashes (folder/index.md), and #heading fragments.
M.resolveMdLink = function(fname)
  fname = fname:gsub('#.*$', '')
  -- fragment-only link (](#heading)): nothing to resolve on disk
  if fname == '' then return fname end
  fname = vim.uri_decode(fname)
  local base
  if fname:sub(1, 1) == '/' then
    local root = vim.fs.root(0, M.root_markers)
    if not root then return fname end
    base = root .. fname
  else
    base = vim.fn.expand('%:p:h') .. '/' .. fname
  end
  local stripped = (base:gsub('/+$', ''))
  for _, candidate in ipairs({ stripped, stripped .. '.md', stripped .. '/index.md' }) do
    local stat = vim.uv.fs_stat(candidate)
    if stat and stat.type == 'file' then return candidate end
  end
  return stripped
end

local html_entities = { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'", nbsp = " " }

-- Turn raw <title> contents into safe markdown link text: decode common
-- entities, collapse whitespace/newlines, and escape brackets so the link
-- syntax can't be broken by the page's title
M.cleanTitle = function(raw)
  local t = raw:gsub("&#[xX](%x+);", function(h)
    local ok, ch = pcall(vim.fn.nr2char, tonumber(h, 16))
    return ok and ch or ""
  end)
  t = t:gsub("&#(%d+);", function(d)
    local ok, ch = pcall(vim.fn.nr2char, tonumber(d))
    return ok and ch or ""
  end)
  t = t:gsub("&(%a+);", function(name) return html_entities[name] end)
  t = vim.trim((t:gsub("%s+", " ")))
  t = t:gsub("([%[%]])", "\\%1")
  return t
end

local title_placeholder = "fetching title…"
local title_ns = vim.api.nvim_create_namespace("pwnvim_url_title")

local function title_from_html(url, body)
  local raw = body:match("<[Tt][Ii][Tt][Ll][Ee][^>]*>([^<]+)</[Tt][Ii][Tt][Ll][Ee]>")
      or body:match("<[Hh]1[^>]*>([^<]+)</[Hh]1>")
  local title = raw and M.cleanTitle(raw) or ""
  if title == "" then
    title = url:match("^https?://([^/?#:]+)") or "untitled"
  end
  return title
end

-- Fetch a page title for a markdown link without blocking; cb(title) runs on
-- the main loop. Never throws: any failure (DNS, timeout, TLS, HTTP 4xx/5xx,
-- curl missing) yields "fetch error" so callers always produce a usable link.
-- A fetched page with no title falls back to the host name; a non-URL gets "".
M.fetchTitle = function(url, cb)
  if not url:match("^https?://[^%s]+$") then
    return cb("") -- doesn't look like a URL -- avoid curl sadness
  end
  local function fail(why)
    vim.notify("Title fetch failed for " .. url .. ": " .. why, vim.log.levels.WARN, { title = "PasteUrl" })
    cb("fetch error")
  end
  local ok, err = pcall(vim.system, {
    "curl", "--silent", "--show-error", "--location", "--fail",
    "--compressed", "--connect-timeout", "5", "--max-time", "10",
    "--user-agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)",
    "--header", "Accept: text/html,application/xhtml+xml",
    url,
  }, { text = true, timeout = 12000 }, vim.schedule_wrap(function(res)
    if res.code ~= 0 or not res.stdout then
      local why = vim.split(vim.trim(res.stderr or ""), "\n")[1]
      return fail(why ~= "" and why or ("curl exited " .. tostring(res.code)))
    end
    local tok, title = pcall(title_from_html, url, res.stdout)
    if not tok then return fail(tostring(title)) end
    cb(title)
  end))
  if not ok then fail(tostring(err)) end
end

-- Replace [scol, ecol) on 0-based row with "[<placeholder>](url)" right away,
-- then swap the real title in when the fetch finishes. An extmark tracks the
-- placeholder so typing/edits elsewhere don't matter; if the user edited the
-- placeholder itself it's left alone. Returns the inserted link's byte length.
M.insertLinkAsync = function(bufnr, row, scol, ecol, url)
  local link = "[" .. title_placeholder .. "](" .. url .. ")"
  vim.api.nvim_buf_set_text(bufnr, row, scol, row, ecol, { link })
  local mark = vim.api.nvim_buf_set_extmark(bufnr, title_ns, row, scol + 1, {
    end_row = row,
    end_col = scol + 1 + #title_placeholder,
    hl_group = "Comment",
    right_gravity = false,
    end_right_gravity = true,
  })
  M.fetchTitle(url, function(title)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, title_ns, mark, { details = true })
    vim.api.nvim_buf_del_extmark(bufnr, title_ns, mark)
    if #pos == 0 then return end
    local r, c, d = pos[1], pos[2], pos[3]
    if d.end_row ~= r then return end
    local current = vim.api.nvim_buf_get_text(bufnr, r, c, r, d.end_col, {})[1]
    if current ~= title_placeholder then return end
    vim.api.nvim_buf_set_text(bufnr, r, c, r, d.end_col, { title })
  end)
  return #link
end

-- Turn the WORD under the cursor (a bare URL) into a titled link in place
M.transformUrlUnderCursorToMdLink = function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if not line:sub(col + 1, col + 1):match("%S") then
    vim.notify("No URL under cursor", vim.log.levels.WARN, { title = "PasteUrl" })
    return
  end
  local s = col + 1
  while s > 1 and line:sub(s - 1, s - 1):match("%S") do s = s - 1 end
  local e = line:find("%s", col + 1) or (#line + 1)
  local url = line:sub(s, e - 1)
  M.insertLinkAsync(0, row - 1, s - 1, e - 1, url)
  vim.api.nvim_win_set_cursor(0, { row, s - 1 })
end

-- Turn a (single-line, charwise) visual selection holding a URL into a
-- titled link in place
M.selectionToMdLink = function()
  local vpos, cpos = vim.fn.getpos("v"), vim.fn.getpos(".")
  local mode = vim.api.nvim_get_mode().mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  if vpos[2] ~= cpos[2] then
    vim.notify("Select a URL on a single line", vim.log.levels.WARN, { title = "PasteUrl" })
    return
  end
  local row = vpos[2]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local s, e = math.min(vpos[3], cpos[3]), math.max(vpos[3], cpos[3])
  if mode == "V" then
    s, e = 1, #line
  else
    -- extend end over a multibyte char under the cursor
    e = e + #vim.fn.matchstr(line:sub(e), ".") - 1
  end
  local text = line:sub(s, e)
  local lead = #text:match("^%s*")
  local url = vim.trim(text)
  if url == "" then return end
  M.insertLinkAsync(0, row - 1, s - 1 + lead, s - 1 + lead + #url, url)
  vim.api.nvim_win_set_cursor(0, { row, s - 1 + lead })
end

-- Insert the clipboard URL as [title](url). In normal mode the link goes
-- after the cursor (like `a`); in insert mode it goes at the insertion point
-- and the cursor lands right after it so typing can continue. The title fills
-- in asynchronously.
M.pasteUrl = function()
  local url = vim.trim(vim.fn.getreg('*'))
  if url == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN, { title = "PasteUrl" })
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local insert_mode = vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
  if not insert_mode and #line > 0 then
    -- normal mode: after the char under the cursor (which may be multibyte)
    col = col + #vim.fn.matchstr(line:sub(col + 1), ".")
  end
  local len = M.insertLinkAsync(0, row - 1, col, col, url)
  if insert_mode then
    vim.api.nvim_win_set_cursor(0, { row, col + len })
  else
    -- one past the link like before (clamped to the last char at EOL)
    vim.api.nvim_win_set_cursor(0, { row, math.min(col + len, #line + len - 1) })
  end
end

-- macOS only: ask Mail.app for the messages the user has selected and turn each
-- into a message:// URL. Message ids are angle-bracketed, so they're escaped
-- (%3C/%3E) to survive being pasted into markdown. Returns a list of urls or
-- nil if Mail errored out (nothing selected, no automation permission, etc).
M.getSelectedMailLinks = function()
  local result = vim.system({
    'osascript',
    '-e', 'tell application "Mail"',
    '-e', 'set s to selection',
    '-e', 'if (count s) = 0 then error "No messages selected in Mail."',
    '-e', 'set r to ""',
    '-e', 'repeat with m in s',
    '-e', 'if r is not "" then set r to r & linefeed',
    '-e', 'set r to r & "message://%3C" & (message id of m) & "%3E"',
    '-e', 'end repeat',
    '-e', 'end tell',
    '-e', 'return r'
  }, { text = true }):wait(30000) -- generous: first run pops a permission dialog

  if result.code ~= 0 then
    local err = vim.trim(result.stderr or "")
    if err == "" then err = "osascript failed (code " .. tostring(result.code) .. ")" end
    vim.notify(err, vim.log.levels.ERROR, { title = "Mail links" })
    return nil
  end
  return vim.split(vim.trim(result.stdout or ""), "\n", { trimempty = true })
end

M.pasteMailLinks = function()
  local links = require("pwnvim.markdown").getSelectedMailLinks()
  if not links or #links == 0 then return end
  -- charwise put after the cursor, same landing spot as pasteUrl's `a`
  vim.api.nvim_put(links, "c", true, true)
end

M.newMeetingNote = function()
  local zk = require("zk.commands")
  M.pick_folder_and_title(vim.env.ZK_NOTEBOOK_DIR, 'Calendar/Meetings', function(folder, title)
    zk.get('ZkNew')({ dir = folder, title = title })
  end)
end

M.newGeneralNote = function()
  local zk = require("zk.commands")
  local zkfolder = require("zk.util").notebook_root(vim.api.nvim_buf_get_name(0))
  local subdir = ""
  if not zkfolder then
    zkfolder = vim.env.ZK_NOTEBOOK_DIR
    subdir = ''
  else
    if vim.fn.isdirectory(zkfolder) == 1 then
      subdir = ''
    elseif vim.fn.isdirectory(zkfolder .. "/content") == 1 then
      subdir = "content"
    end
  end

  M.pick_folder_and_title(zkfolder, subdir, function(folder, title)
    zk.get('ZkNew')({ dir = folder, title = title })
  end)
end

M.newDailyNote = function()
  local zk = require("zk.commands")
  zk.get("ZkNew")({ dir = vim.env.ZK_NOTEBOOK_DIR .. '/Calendar/Daily', title = os.date("%Y%m%d") })
end

M.pick_folder_and_title = function(base, subdir, callback)
  M.pick_folder(base, subdir, function(folder)
    vim.ui.input({ prompt = 'Title: ', default = '' }, function(input)
      if input ~= nil then
        callback(folder, input)
      end
    end)
  end)
end

M.pick_folder = function(base, subdir, callback)
  local scan = require 'plenary.scandir'
  local full_path_folders = scan.scan_dir(base .. '/' .. subdir, {
    add_dirs = true,
    only_dirs = true,
    respect_gitignore = true,
    depth = 5,
  })
  table.insert(full_path_folders, 1, base .. '/' .. subdir)

  -- Create items for snacks picker
  local items = {}
  for _, folder in ipairs(full_path_folders) do
    local display = (string.gsub(folder, base .. '/' .. subdir, ''))
    if display == '' then display = '/' end
    table.insert(items, {
      text = display,
      file = folder,
    })
  end

  Snacks.picker.pick({
    source = "custom",
    title = "Pick Folder",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        callback(item.file)
      end
    end,
  })
end

return M
