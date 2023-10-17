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

  vim.bo.syntax = "off" -- we use treesitter exclusively on markdown now
  -- except temp off until https://github.com/MDeiml/tree-sitter-markdown/issues/114

  require('pwnvim.markdown').markdownsyntax()
  require('pwnvim.markdown').setupmappings(bufnr)

  vim.diagnostic.config({ virtual_lines = false }) -- no need to see this in markdown -- wavy underlines good enough

  -- no idea why the lua version of adding the command is failing
  -- vim.api.nvim_buf_add_user_command(0, 'PasteUrl', function(opts) require('pwnvim.markdown').pasteUrl() end, {})
  vim.cmd("command! PasteUrl lua require('pwnvim.markdown').pasteUrl()")


  -- Hologram displays image thumbnails in-terminal while editing markdown in vim
  -- This is wonderful when it's working, but I sometimes get too many open files errors that seem to come from this plugin. Plus
  -- some weirdness where my entire terminal (kitty) completely hangs for a time. Especially when typing in an alt description.
  -- So, sadly, commenting out for now. 2023-01-19
  -- if vim.env.KITTY_INSTALLATION_DIR and not vim.g.neovide then
  --   vim.cmd('packadd hologram.nvim')
  --   require('hologram').setup {
  --     auto_display = true -- WIP automatic markdown image display, may be prone to breaking
  --   }
  -- end
  vim.cmd('packadd clipboard-image.nvim')
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

  -- I have historically always used spaces for indents wherever possible including markdown
  -- Changing now to use tabs because NotePlan 3 can't figure out nested lists that are space
  -- indented and I go back and forth between that and nvim (mainly for iOS access to notes).
  -- So, for now, this is the compatibility compromise. 2022-09-27
  -- UPDATE 2023-08-18: going to do ugly stateful things and check the CWD and only
  --         use tabs when in a Notes directory so I stop screwing up READMEs.
  if (string.find(vim.fn.getcwd(), "Notes") or
        string.find(vim.fn.getcwd(), "noteplan")) then
    require('pwnvim.options').tabindent()
    require('pwnvim.options').retab() -- turn spaces to tabs when markdown file is opened
  else
    require('pwnvim.options').twospaceindent()
    -- require('pwnvim.options').retab() -- turn tabs to spaces when markdown file is opened
  end
  -- Temporary workaround for https://github.com/nvim-telescope/telescope.nvim/issues/559
  -- which prevents folds from being calculated initially when launching from telescope
  -- Has the lousy side-effect of calculating them twice if not launched from telescope
  vim.cmd("normal zx")
end

M.setupmappings = function(bufnr)
  -- normal mode mappings
  local mapnlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapn)
  local mapilocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapi)
  local mapvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapv)
  local mapnviclocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapnvic)

  mapnlocal("<leader>m", ':silent !open -a Marked\\ 2.app "%:p"<cr>', "Open Marked preview")
  mapnlocal("gl*", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]],
    "Add bullets")
  mapnlocal("gl>", [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]],
    "Add block quote")
  mapnlocal("gl[", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>5l]],
    "Add task")
  mapnlocal("gt", require('pwnvim.markdown').transformUrlUnderCursorToMdLink, "Convert URL to link")
  mapnlocal("gp", require('pwnvim.markdown').pasteUrl, "Paste URL as link")
  mapnlocal("<C-M-v>", require('pwnvim.markdown').pasteUrl, "Paste URL as link")
  mapnlocal("<D-b>", 'ysiwe', "Bold")
  mapnlocal("<leader>b", 'ysiwe', "Bold")
  mapnlocal("<D-i>", 'ysiw_', "Italic")
  mapnlocal("<leader>i", 'ysiw_', "Italic")
  mapnlocal("<D-1>", 'ysiw`', "Code block")
  mapnlocal("<leader>`", 'ysiw`', "Code block")
  mapnlocal("<D-l>", 'ysiW]%a(`', "Link")

  -- insert mode mappings
  mapilocal("<C-M-v>", require('pwnvim.markdown').pasteUrl, "Paste URL as link")
  mapilocal("<D-b>", "****<C-O>h", "Bold")
  mapilocal("<D-i>", [[__<C-O>h]], "Italic")
  mapilocal("<D-1>", [[``<C-O>h]], "Code block")
  mapilocal("<tab>", require('pwnvim.markdown').indent, "Indent")
  mapilocal("<s-tab>", require('pwnvim.markdown').outdent, "Outdent")

  mapnviclocal("<F7>", function()
    vim.cmd("lvimgrep /^#/ %")
    require("trouble").toggle("loclist")
  end, "Show doc outline")

  -- visual mode mappings
  mapvlocal("gl*", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]],
    "Add bullets")
  mapvlocal("gl>", [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]], "Add quotes")
  mapvlocal("gl[", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*)/\1* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]],
    "Add task")
  mapvlocal("gt", "<cmd>lua require('pwnvim.markdown').transformUrlUnderCursorToMdLink()<cr>", "Convert URL to link")
  mapvlocal("<D-b>", "Se", "Bold")
  mapvlocal("<leader>b", "Se", "Bold")
  mapvlocal("<D-i>", "S_", "Italic")
  mapvlocal("<leader>i", "S_", "Italic")
  mapvlocal("<D-1>", "S`", "Code ticks")
  mapvlocal("<leader>`", "S_", "Code ticks")
  mapvlocal("<D-l>", "S]%a(", "Code ticks")

  -- task shortcuts
  M.mapvlocal("<leader>ta", 'grep "^\\s*[*-] \\[ \\] "<cr>:Trouble quickfix', "All tasks quickfix")
  M.mapnlocal("<leader>td", require("pwnvim.tasks").completeTaskDirect, "Task done")
  M.mapvlocal("<leader>td", "luado return require('pwnvim.tasks').completeTask(line)", "Done")
  M.mapnlocal("<leader>tc", require("pwnvim.tasks").createTaskDirect, "Task create")
  M.mapnlocal("<leader>ts", require("pwnvim.tasks").scheduleTaskPrompt, "Task schedule")
  M.mapvlocal("<leader>ts", require("pwnvim.tasks").scheduleTaskBulk, "Schedule")
  M.mapnlocal("<leader>tt", require("pwnvim.tasks").scheduleTaskTodayDirect, "Task move today")
  M.mapvlocal("<leader>tt", "luado return require('pwnvim.tasks').scheduleTaskToday(line)<cr>", "Today")
end

M.markdownsyntax = function()
  vim.api.nvim_exec([[
    let m = matchadd("bareLink", "\\<https:[a-zA-Z?&,;=$+%#/.!~':@0-9_-]*")
    " let m = matchadd("markdownCheckboxChecked", "[*-] \\[x\\] ")
    let m = matchadd("markdownCheckboxCanceled", "[*-] \\[-\\] .\\+")
    let m = matchadd("markdownCheckboxPostponed", "[*-] \\[>\\] .\\+")
    " below is because Noteplan uses capital X and default styling is a link on [X] so this will at least make it green
    let m = matchadd("@text.todo.checked", "[*-] \\[[xX]\\] ")
    let m = matchadd("markdownTag", '#\w\+')
    let m = matchadd("markdownStrikethrough", "\\~\\~[^~]*\\~\\~")
    let m = matchadd("doneTag", '@done(20[^)]*)')
    let m = matchadd("highPrioTask", "[*-] \\[ \\] .\\+!!!")
  ]], false)
end

local check_backspace = function()
  local col = vim.fn.col "." - 1
  return col == 0 or vim.fn.getline(vim.fn.line(".")):sub(col, col):match "%s"
end

M.indent = function()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*[*-]") then
    local ctrlt = vim.api.nvim_replace_termcodes("<C-t>", true, false, true)
    vim.api.nvim_feedkeys(ctrlt, "n", false)
  elseif check_backspace() then
    -- we are at first col or there is whitespace immediately before cursor
    -- send through regular tab character at current position
    vim.api.nvim_feedkeys("\t", "n", false)
  else
    require 'cmp'.mapping.complete({})
  end
end

M.outdent = function()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*[*-]") then
    local ctrld = vim.api.nvim_replace_termcodes("<C-d>", true, false, true)
    vim.api.nvim_feedkeys(ctrld, "n", false)
  end
end

M.getTitleFor = function(url)
  local curl = require "plenary.curl"
  if not string.match(url, "^https?:[^%s]*$") then
    return "" -- doesn't look like a URL -- avoid curl sadness
  end
  local res = curl.request {
    url = url,
    method = "get",
    accept = "text/html",
    raw = { "-L" } -- follow redirects
  }
  local title = ""
  if res then
    title = string.match(res.body, "<title[^>]*>([^<]+)</title>")
    if not title then title = string.match(res.body, "<h1[^>]*>([^<]+)</h1>") end
  end
  if not title then
    title = "could not get title" -- TODO: put domain here
  end
  return title
end

M.transformUrlUnderCursorToMdLink = function()
  -- local url = vim.fn.expand("<cfile>")
  local url = vim.fn.expand("<cWORD>")
  local title = require("pwnvim.markdown").getTitleFor(url)
  vim.cmd("normal! ciW[" .. title .. "](" .. url .. ")")
end

M.pasteUrl = function()
  local url = vim.fn.getreg('*')
  local title = require("pwnvim.markdown").getTitleFor(url)
  vim.cmd("normal! a[" .. title .. "](" .. url .. ")")
  -- cursor ends up one to the left, so move over right one if possible
  local right = vim.api.nvim_replace_termcodes("<right>", true, false, true)
  vim.api.nvim_feedkeys(right, "n", false)
end

M.newMeetingNote = function()
  local zk = require("zk.commands")
  M.telescope_get_folder_and_title(vim.env.ZK_NOTEBOOK_DIR, 'Notes/meetings', function(folder, title)
    zk.get('ZkNew')({ dir = folder, title = title })
  end)
end

M.newGeneralNote = function()
  local zk = require("zk.commands")
  M.telescope_get_folder_and_title(vim.env.ZK_NOTEBOOK_DIR, 'Notes', function(folder, title)
    zk.get('ZkNew')({ dir = folder, title = title })
  end)
end

M.newDailyNote = function()
  local zk = require("zk.commands")
  zk.get("ZkNew")({ dir = vim.env.ZK_NOTEBOOK_DIR .. '/Calendar', title = os.date("%Y%m%d") })
end

M.telescope_get_folder_and_title = function(base, subdir, callback)
  M.telescope_get_folder(base, subdir, function(folder)
    vim.ui.input({ prompt = 'Title: ', default = '' }, function(input)
      if input ~= nil then
        callback(folder, input)
      end
    end)
  end)
end

M.telescope_get_folder = function(base, subdir, callback)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local sorters = require "telescope.sorters"
  local themes = require "telescope.themes"
  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"

  local entry = function(a)
    local display = (string.gsub(a, base .. '/' .. subdir, ''))
    if (display == '') then display = '/' end
    return {
      value = a,
      display = display,
      ordinal = a
    }
  end
  local scan = require 'plenary.scandir'
  local full_path_folders = scan.scan_dir(base .. '/' .. subdir, {
    add_dirs = true,
    only_dirs = true,
    respect_gitignore = true,
    depth = 3,
  })
  table.insert(full_path_folders, 1, base .. '/' .. subdir)

  local finder = finders.new_table({
    results = full_path_folders,
    entry_maker = entry
  })
  pickers.new({}, {
    cwd = base,
    prompt_title = "Pick Folder",
    finder = finder,
    sorter = sorters.fuzzy_with_index_bias(),
    theme = themes.get_dropdown(),
    attach_mappings =
        function(prompt_bufnr)
          actions.select_default:replace(function()
            local folder = action_state.get_selected_entry()
            -- print(vim.inspect(folder))
            if folder ~= nil then
              actions.close(prompt_bufnr)
              callback(folder["value"])
            end
          end)
          return true
        end
  }):find()
end

return M
