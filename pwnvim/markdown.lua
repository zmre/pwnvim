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

  vim.cmd('packadd render-markdown.nvim')
  require('render-markdown').setup({
    file_types = { 'markdown', "codecompanion" },
    completions = { lsp = { enabled = false } },
    render_modes = { 'n', 'c', 't' },
    anti_conceal = {
      enabled = true,
    },
  })
  -- require('render-markdown').enable()
  require('render-markdown').buf_enable()

  -- Image plugin still slow and buggy 2024-12-01
  -- if os.getenv("TERM") == "wezterm" or os.getenv("TERM") == "kitty" then
  --   vim.cmd('packadd image.nvim')
  --   require("image").setup({
  --     backend = "kitty",
  --     processor = "magick_rock", -- or "magick_cli"
  --     integrations = {
  --       markdown = {
  --         enabled = true,
  --         clear_in_insert_mode = false,
  --         download_remote_images = true,
  --         only_render_image_at_cursor = false,
  --         filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
  --       },
  --       neorg = {
  --         enabled = true,
  --         filetypes = { "norg" },
  --       },
  --       typst = {
  --         enabled = true,
  --         filetypes = { "typst" },
  --       },
  --       html = {
  --         enabled = false,
  --       },
  --       css = {
  --         enabled = false,
  --       },
  --     },
  --     max_width = nil,
  --     max_height = nil,
  --     max_width_window_percentage = nil,
  --     max_height_window_percentage = 50,
  --     window_overlap_clear_enabled = false,                                               -- toggles images when windows are overlapped
  --     window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
  --     editor_only_render_when_focused = false,                                            -- auto show/hide images when the editor gains/looses focus
  --     tmux_show_only_in_active_window = false,                                            -- auto show/hide images in the correct Tmux window (needs visual-activity off)
  --     hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
  --   })
  -- end

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

  -- I have historically always used spaces for indents wherever possible including markdown
  -- Changing now to use tabs because NotePlan 3 can't figure out nested lists that are space
  -- indented and I go back and forth between that and nvim (mainly for iOS access to notes).
  -- So, for now, this is the compatibility compromise. 2022-09-27
  -- UPDATE 2023-08-18: going to do ugly stateful things and check the CWD and only
  --         use tabs when in a Notes directory so I stop screwing up READMEs.
  if (string.find(vim.fn.getcwd(), "Notes") or
        string.find(vim.fn.getcwd(), "noteplan")) then
    require('pwnvim.options').tabindent()
    --require('pwnvim.options').retab() -- turn spaces to tabs when markdown file is opened
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
  local mapnvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapnv)

  mapnlocal("<leader>m", ':silent !open -a Marked\\ 2.app "%:p"<cr>', "Open Marked preview")
  mapnlocal("gl*", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]],
    "Add bullets")
  mapnlocal("gl>", [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]],
    "Add block quote")
  mapnlocal("gl[", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>5l]],
    "Add task")
  mapnlocal("gt", require('pwnvim.markdown').transformUrlUnderCursorToMdLink, "Convert URL to link")
  mapnlocal("<leader>P", require('pwnvim.markdown').pasteUrl, "Paste URL as link")
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

  -- TODO: make this work with blink.cmp
  --mapilocal("<tab>", require('pwnvim.markdown').indent, "Indent")
  --mapilocal("<s-tab>", require('pwnvim.markdown').outdent, "Outdent")

  -- mapnviclocal("<F7>", function()
  --   vim.cmd("lvimgrep /^#/ %")
  --   require("trouble").toggle({ mode = "loclist", position = "right" })
  -- end, "Show doc outline")

  -- visual mode mappings
  mapvlocal("gl*", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*\)/\1* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]],
    "Add bullets")
  mapvlocal("gl>", [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]], "Add quotes")
  mapvlocal("gl[", [[<cmd>let p=getcurpos('.')<cr>:s/^\([ \t]*)/\1* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]],
    "Add task")
  mapvlocal("gt", "<cmd>lua require('pwnvim.markdown').transformUrlUnderCursorToMdLink()<cr>", "Convert URL to link")
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
    let m = matchadd("@text.todo.checked", "[*-] \\[[xX]\\] ")
    let m = matchadd("markdownTag", '#\w\+')
    let m = matchadd("markdownStrikethrough", "\\~\\~[^~]*\\~\\~")
    let m = matchadd("doneTag", '@done(20[^)]*)')
    let m = matchadd("highPrioTask", "[*-] \\[ \\] .\\+!!!")
  ]], { output = false })
end

local check_backspace = function()
  local col = vim.fn.col "." - 1
  return col == 0 or vim.fn.getline(vim.fn.line(".")):sub(col, col):match "%s"
end

--[[ M.indent = function()
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
end ]]

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
  M.pick_folder_and_title(vim.env.ZK_NOTEBOOK_DIR, 'meetings', function(folder, title)
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
  zk.get("ZkNew")({ dir = vim.env.ZK_NOTEBOOK_DIR .. '/daily', title = os.date("%Y%m%d") })
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
    depth = 3,
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
