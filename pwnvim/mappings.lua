-- We use which-key in mappings, which is loaded before plugins, so set up here
local which_key = require("which-key")
local enter = vim.api.nvim_replace_termcodes("<cr>", true, false, true)

local function map(mode, lhs, rhs, desc, opts)
  opts = opts or { silent = true, noremap = true }
  opts["desc"] = desc or ""
  vim.keymap.set(
    mode or "n", -- can also be a map like {"n", "c"}
    lhs,         -- key to bind
    rhs,         -- string or function
    opts
  )
end
local function mapn(lhs, rhs, desc, opts)
  map("n", lhs,
    type(rhs) == "string" and ("<cmd>%s<cr>"):format(rhs) or rhs,
    desc, opts)
end
local function mapv(lhs, rhs, desc, opts)
  map("v", lhs,
    type(rhs) == "string" and ("<cmd>%s<cr>"):format(rhs) or rhs,
    desc, opts)
end
local function mapnv(lhs, rhs, desc, opts)
  map({ "n", "v" }, lhs,
    type(rhs) == "string" and ("<cmd>%s<cr>"):format(rhs) or rhs,
    desc, opts)
end
local function mapic(lhs, rhs, desc, opts)
  map({ "i", "c" }, lhs, rhs, desc, opts)
end
local function mapnvic(lhs, rhs, desc, opts)
  map({ "n", "v", "i", "c" }, lhs,
    type(rhs) == "string" and ("<cmd>%s<cr>"):format(rhs) or rhs,
    desc, opts)
end
local function mapi(lhs, rhs, desc, opts)
  map("i", lhs, rhs, desc, opts)
end
local function mapc(lhs, rhs, desc, opts)
  map("c", lhs, rhs, desc, opts)
end
local function maplocal(mode, lhs, rhs, opts)
  opts = opts or { silent = true, noremap = true }
  opts["buffer"] = true
  map(mode, lhs, rhs, opts)
end

which_key.setup({
  plugins = {
    marks = true,      -- shows a list of your marks on ' and `
    registers = true,  -- shows your registers on " in NORMAL or <C-r> in INSERT mode
    spelling = {
      enabled = true,  -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      suggestions = 20 -- how many suggestions should be shown in the list?
    },
    -- the presets plugin, adds help for a bunch of default keybindings in Neovim
    -- No actual key bindings are created
    presets = {
      operators = false,   -- adds help for operators like d, y, ... and registers them for motion / text object completion
      motions = false,     -- adds help for motions
      text_objects = true, -- help for text objects triggered after entering an operator
      windows = true,      -- default bindings on <c-w>
      nav = true,          -- misc bindings to work with windows
      z = true,            -- bindings for folds, spelling and others prefixed with z
      g = true             -- bindings for prefixed with g
    }
  },
  -- hidden = {
  --   "<silent>", "<CMD>", "<cmd>", "<Cmd>", "<cr>", "<CR>", "call", "lua", "^:",
  --   "^ "
  -- }, -- hide mapping boilerplate
  show_help = true, -- show help message on the command line when the popup is visible
  triggers = "auto" -- automatically setup triggers
  -- triggers = {"<leader>"}
  -- triggers_nowait = {"'", '"', "y", "d"}
})

which_key.register({
  mode = { "n", "v" },
  ["]"] = { name = "+next" },
  ["["] = { name = "+prev" },
  ["<leader>f"] = { name = "+find" },
  ["<leader>g"] = { name = "+git" },
  ["<leader>h"] = { name = "+hunk" },
  ["<leader>i"] = { name = "+indent" },
  ["<leader>l"] = { name = "+lsp" },
  ["<leader>n"] = { name = "+notes" },
  ["<leader>t"] = { name = "+tasks" },
})

-- This file is for mappings that will work regardless of filetype. Always available.

-- ALL MODE (EXCEPT OPERATOR) MAPPINGS
-- Make F1 act like escape for accidental hits
map({ "n", "v", "i", "c" }, "<F1>", "<Esc>", "Escape")
-- Make F2 bring up a file browser
mapnvic("<F2>", "Oil .", "Toggle file browser")
-- Make F4 toggle invisible characters (locally)
mapnvic("<F4>", function()
  if vim.opt_local.list:get() then
    vim.opt_local.list = false
    vim.opt_local.conceallevel = 2
    vim.cmd("IndentBlanklineEnable")
  else
    vim.opt_local.list = true
    vim.opt_local.conceallevel = 0
    vim.cmd("IndentBlanklineDisable") -- indent lines hide some chars like tab
  end
end, "Toggle show invisible chars")
-- Make ctrl-p open a file finder
-- When using ctrl-p, screen out media files that we probably don't want
-- to open in vim. And if we really want, then we can use ,ff
mapnvic("<c-p>", require("telescope.builtin").find_files, "Find files")
mapnvic("<F9>", "TZAtaraxis", "Focus mode")
-- Make F10 quicklook. Not sure how to do this best in linux so mac only for now
mapnvic("<F10>", 'silent !qlmanage -p "%"', "Quicklook (mac)")
mapnvic("<F12>", 'syntax sync fromstart', "Restart highlighting")
-- Pane navigation integrated with tmux
mapnvic("<c-h>", "TmuxNavigateLeft", "Pane left")
mapnvic("<c-j>", "TmuxNavigateDown", "Pane down")
mapnvic("<c-k>", "TmuxNavigateUp", "Pane up")
mapnvic("<c-l>", "TmuxNavigateRight", "Pane right")
mapnvic("<D-w>", "Bdelete", "Close buffer")
mapnvic("<A-w>", "Bdelete", "Close buffer")
mapnvic("<M-w>", "Bdelete", "Close buffer")
mapnvic("<D-n>", "enew", "New buffer")
mapnvic("<D-t>", "tabnew", "New tab")
mapnvic("<D-s>", "write", "Save buffer")
mapnvic("<D-q>", "quit", "Quit")
-- Magic buffer-picking mode
mapnvic("<M-b>", "BufferLinePick", "Pick buffer by letter")

-- Copy and paste ops mainly for neovide / gui apps
mapn("<D-v>", 'normal "+p', "Paste")
mapv("<D-c>", 'normal "+ygv', "Copy")
mapv("<D-v>", 'normal "+p', "Paste")
mapic("<D-v>", '<c-r>+', "Paste", { noremap = true, silent = false })
map("t", "<D-v>", '<C-\\><C-n>"+pa', "Paste")

-- NORMAL MODE ONLY MAPPINGS
map("n", "<A-up>", "[e", "Move line up")
map("n", "<A-down>", "]e", "Move line down")
mapn("zi", function() -- override default fold toggle behavior to fix fold columns and scan
  if vim.wo.foldenable then
    -- Disable completely
    vim.wo.foldenable = false
    vim.wo.foldcolumn = "0"
  else
    vim.wo.foldenable = true
    vim.wo.foldcolumn = "auto:4"
    vim.cmd("normal zx") -- reset folds
  end
end, "Toggle folding"
)
map("n", "<F8>", '"=strftime("%Y-%m-%d")<CR>P', "Insert date")
mapic("<F8>", '<C-R>=strftime("%Y-%m-%d")<CR>', "Insert date at cursor", { noremap = true, silent = false })
map("n", "<D-[>", "<<", "Outdent")
map("n", "<D-]>", ">>", "Indent")
map("n", "n", "nzzzv", "Center search hits vertically on screen and expand folds if hit is inside")
map("n", "N", "Nzzzv", "Center search hits vertically on screen and expand folds if hit is inside")
map("n", "<c-d>", "<c-d>zz", "Half scroll down keep cursor center screen")
map("n", "<c-u>", "<c-u>zz", "Half scroll up keep cursor center screen")
-- gx is a built-in to open URLs under the cursor, but when
-- not using netrw, it doesn't work right. Or maybe it's just me
-- but anyway this command works great.
-- /Users/pwalsh/Documents/md2rtf-style.html
-- ../README.md
-- ~/Desktop/Screen Shot 2018-04-06 at 5.19.32 PM.png
-- [abc](https://github.com/adsr/mle/commit/e4dc4314b02a324701d9ae9873461d34cce041e5.patch)
mapn("gx", 'silent !open "<c-r><c-f>" || xdg-open "<c-r><c-f>"', "Launch URL or path")
mapn("*",
  function()
    local text = "\\<" .. string.gsub(vim.fn.expand("<cword>"), "/", "\\/") ..
        "\\>"
    -- Can't find a way to have flash jump keep going past what's visible on the screen
    vim.api.nvim_feedkeys("/\\V" .. text .. enter, 'n', false)
  end, "Find word under cursor forward"
)
mapn("#",
  function()
    local text = "\\<" .. string.gsub(vim.fn.expand("<cword>"), "?", "\\?") ..
        "\\>"
    vim.api.nvim_feedkeys("?\\V" .. text .. enter, 'n', false)
  end, "Find word under cursor backward"
)
mapn("g*",
  function()
    -- Same as above, but don't qualify as full word only
    local text = string.gsub(vim.fn.expand("<cword>"), "/", "\\/")
    vim.api.nvim_feedkeys("/\\V" .. text .. enter, 'n', false)
  end, "Find partial word under cursor forward"
)
mapn("g#",
  function()
    -- Same as above, but don't qualify as full word only
    local text = string.gsub(vim.fn.expand("<cword>"), "?", "\\?")
    vim.api.nvim_feedkeys("?" .. text .. enter, 'n', false)
    -- vim.cmd("?\\V" .. text) -- works, but doesn't trigger flash
  end, "Find partial word under cursor backward"
)
map("n", "<space>", [[@=(foldlevel('.')?'za':"\<Space>")<CR>]], "Toggle folds if enabled")
which_key.register({
  -- Adjust font sizes
  ["<D-=>"] = {
    [[:silent! let &guifont = substitute(&guifont, ':h\zs\d\+',
  \ '\=eval(submatch(0)+1)', '')<CR>]], "Increase font size"
  },
  ["<C-=>"] = {
    [[:silent! let &guifont = substitute(&guifont, ':h\zs\d\+',
  \ '\=eval(submatch(0)+1)', '')<CR>]], "Increase font size"
  },
  ["<D-->"] = {
    [[:silent! let &guifont = substitute(&guifont, ':h\zs\d\+',
  \ '\=eval(submatch(0)-1)', '')<CR>]], "Shrink font size"
  },
  ["<C-->"] = {
    [[:silent! let &guifont = substitute(&guifont, ':h\zs\d\+',
  \ '\=eval(submatch(0)-1)', '')<CR>]], "Shrink font size"
  },
  ["<leader>p"] = { '<cmd>normal "*p<cr>', "paste" },
  ["[0"] = { "<cmd>BufferLinePick<CR>", "Pick buffer by letter" },
  ["]0"] = { "<cmd>BufferLinePick<CR>", "Pick buffer by letter" }
}, { mode = "n" })

map("v", "gx", '"0y:silent !open "<c-r>0" || xdg-open "<c-r>0"<cr>gv', "Launch URL or path")
-- When pasting over selected text, keep original register value
map("v", "p", '"_dP', "Paste over selected no store register")
-- keep visual block so you can move things repeatedly
map("v", "<", "<gv", "Outdent and preserve block")
map("v", ">", ">gv", "Indent and preserve block")
mapi("<D-[>", "<C-d>", "Outdent")
mapi("<D-]>", "<C-t>", "Indent")
map("v", "<D-[>", "<gv", "Outdent and preserve block")
map("v", "<D-]>", ">gv", "Indent and preserve block")
map("v", "<A-Up>", "[egv", "Move line up preserve block")
map("v", "<A-Down>", "]egv", "Move line down preserve block")

-- emacs bindings to jump around in lines
mapi("<C-e>", "<C-o>A", "Jump to end of line")
mapi("<C-a>", "<C-o>I", "Jump to start of line")

-- Send cursor somewhere on screen and pick a text object from it.
-- Uses operator pending mode so you start it with something like `yr` then
-- after jump pick the text object like `iw` and you'll copy that other thing
-- and be back where you were at the start.
map("o", "R", require("flash").remote, "Remote operation via Flash")
map("o", "<c-s>", require("flash").jump, "Flash select")
map("o", "r", require("flash").treesitter, "Flash select")
--
-- Move visually selected lines up and down
-- vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
-- vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

local leader_mappings = {
  e = { "<cmd>Oil<cr>", "Find current file in file browser" },
  ["/"] = { "<cmd>nohlsearch<CR>", "Clear Highlight" },
  x = { "<cmd>Bdelete!<CR>", "Close Buffer" },
  q = {
    [["<cmd>".(get(getqflist({"winid": 1}), "winid") != 0? "cclose" : "botright copen")."<cr>"]],
    "Toggle Quicklist"
  },
  f = {
    name = "Find",
    b = {
      "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<cr>",
      "Buffers"
    },
    d = { require('telescope.builtin').lsp_document_symbols, "Document symbols search" },
    f = { require('telescope.builtin').find_files, "Files" },
    g = { require('telescope.builtin').live_grep, "Grep" },
    h = { "<cmd>Telescope frecency workspace=CWD theme=dropdown<cr>", "History Local" },
    k = { require('telescope.builtin').keymaps, "Keymaps" },
    l = { require('telescope.builtin').loclist, "Loclist" },
    n = { function() require('zk.commands').get("ZkNotes")({ sort = { 'modified' } }) end, "Find notes" },
    o = { require('telescope.builtin').oldfiles, "Old File History Global" },
    p = { "<cmd>Telescope projects<cr>", "Projects" },
    q = { require('telescope.builtin').quickfix, "Quickfix" },
    t = {
      '<cmd>lua require(\'telescope.builtin\').grep_string{search = "^\\\\s*[*-] \\\\[ \\\\]", previewer = false, glob_pattern = "*.md", use_regex = true, disable_coordinates=true}<cr>',
      "Todos"
    },
    z = { function()
      require("pwnvim.plugins").telescope_get_folder_common_folders({
        ".config", "src/sideprojects", "src/icl", "src/icl/website.worktree", "src/personal", "src/gh",
        "Sync/Private", "Sync/Private/Finances", "Sync/IronCore Docs", "Sync/IronCore Docs/Legal",
        "Sync/IronCore Docs/Finances", "Sync/IronCore Docs/Design",
        "Notes", "Notes/Notes", "Notes/Notes/meetings"
      }, 1, function(folder)
        vim.cmd.lcd(folder)
        require("oil").open(folder) -- if we bail on picking a file, we have the file browser as fallback
        require("telescope.builtin").find_files()
      end)
    end, "Open folder" },
  },
  -- Quickly change indent defaults in a file
  i = {
    name = "Indent",
    ["1"] = { require('pwnvim.options').tabindent, "Tab" },
    ["2"] = { require('pwnvim.options').twospaceindent, "Two Space" },
    ["4"] = { require('pwnvim.options').fourspaceindent, "Four Space" },
    r = { "<cmd>%retab!<cr>", "Change existing indent to current with retab" }
  },
  g = {
    name = "Git",
    s = { require('telescope.builtin').git_status, "Status" },
    b = { require('telescope.builtin').git_branches, "Branches" },
    c = { require('telescope.builtin').git_commits, "Commits" },
    h = { require('gitsigns').toggle_current_line_blame, "Toggle Blame" },
    ["-"] = { require('gitsigns').reset_hunk, "Reset Hunk" },
    ["+"] = { require('gitsigns').stage_hunk, "Stage Hunk" }
  },
  ["lcd"] = { "<cmd>lcd %:h<cr>", "Change local dir to path of current file" },
  n = {
    name = "Notes",
    d = { require("pwnvim.markdown").newDailyNote, "New diary" },
    e = {
      '<cmd>!mv "<cfile>" "<c-r>=expand(\'%:p:h\')<cr>/"<cr>',
      "Embed file moving to current file's folder"
    },
    f = { "<Cmd>ZkNotes { sort = { 'modified' }}<CR>", "Find" },
    g = { require('pwnvim.plugins').grammar_check, "Check Grammar" },
    h = { "<cmd>edit ~/Notes/Notes/HotSheet.md<CR>", "Open HotSheet" },
    i = {
      c = {
        "<cmd>r!/opt/homebrew/bin/icalBuddy --bullet '* ' --timeFormat '\\%H:\\%M' --dateFormat '' --noPropNames --noCalendarNames --excludeAllDayEvents --includeCals 'IC - Work' --includeEventProps datetime,title,attendees,location --propertyOrder datetime,title,attendees,location --propertySeparators '| |\\n    * |\\n    * | |' eventsToday<cr>",
        "Insert today's calendar"
      },
      o = { "<cmd>r!gtm-okr goals<cr>", "Insert OKRs" },
      j = {
        "<cmd>r!( (curl -s https://icanhazdadjoke.com/ | grep '\\\"subtitle\\\"') || curl -s https://icanhazdadjoke.com/ ) | sed 's/<[^>]*>//g' | sed -z 's/\\n/ /'<cr>",
        "Insert joke"
      }
    },
    m = { require("pwnvim.markdown").newMeetingNote, "New meeting" },
    n = { require("pwnvim.markdown").newGeneralNote, "New" },
    t = { "<cmd>ZkTags<CR>", "Open by tag" }
    -- in open note (defined in plugins.lua as local-only shortcuts):
    -- p: new peer note
    -- l: show outbound links
    -- r: show outbound links
    -- i: info preview
  },
  t = {
    name = "Tasks",
    -- d = { "<cmd>lua require('pwnvim.tasks').completeTask()<cr>", "Done" },
    d = { require("pwnvim.tasks").completeTaskDirect, "Task done" },
    c = { require("pwnvim.tasks").createTaskDirect, "Task create" },
    s = { require("pwnvim.tasks").scheduleTaskPrompt, "Task schedule" },
    t = { require("pwnvim.tasks").scheduleTaskTodayDirect, "Task move today" }
  },
  -- Set cwd to current file's dir
  ["cd"] = { "<cmd>cd %:h<cr>", "Change dir to path of current file" },
  ["sd"] = {
    [[:echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')<CR>]],
    "Debug syntax files"
  }
}
local leader_visual_mappings = {
  t = {
    name = "Tasks",
    a = {
      ':grep "^\\s*[*-] \\[ \\] "<cr>:Trouble quickfix<cr>',
      "All tasks quickfix"
    },
    -- d = { function() require("pwnvim.tasks").eachSelectedLine(require("pwnvim.tasks").completeTask) end, "Done" },
    d = { ":luado return require('pwnvim.tasks').completeTask(line)<cr>", "Done" },
    s = { require("pwnvim.tasks").scheduleTaskBulk, "Schedule" },
    -- s needs a way to call the prompt then reuse the value
    -- t = { function() require("pwnvim.tasks").eachSelectedLine(require("pwnvim.tasks").scheduleTaskToday) end, "Today" },
    t = {
      ":luado return require('pwnvim.tasks').scheduleTaskToday(line)<cr>",
      "Today"
    }
  },
  n = {
    e = {
      '"0y:!mv "<c-r>0" "<c-r>=expand(\'%:p:h\')<cr>/"<cr>',
      "Embed file moving to current file's folder"
    },
    f = { ":'<,'>ZkMatch<CR>", "Find Selected" }
  },
  i = leader_mappings.i,
  f = leader_mappings.f,
  e = leader_mappings.e,
  q = leader_mappings.q,
  x = leader_mappings.x
}

which_key.register(leader_mappings, {
  mode = "n",     -- NORMAL mode
  prefix = "<leader>",
  buffer = nil,   -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true,  -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true   -- use `nowait` when creating keymaps
})
which_key.register(leader_visual_mappings, {
  mode = "v",     -- VISUAL mode
  prefix = "<leader>",
  buffer = nil,   -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true,  -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true   -- use `nowait` when creating keymaps
})

which_key.register({
  ["<D-j>"] = { "gj", "Down screen line" },
  ["<D-k>"] = { "gk", "Up screen line" },
  ["<D-4>"] = { "g$", "End of screen line" },
  ["<D-6>"] = { "g^", "Beginning of screen line" },
  -- Visually select the text that was last edited/pasted
  -- Similar to gv but works after paste
  ["gV"] = { "`[v`]", "Visually select the text last edited (after paste)" },
  -- Have ctrl-l continue to do what it did, but also temp clear search match highlighting
  Y = { "y$", "Yank to end of line" },
  --["-"] = { "<cmd>NvimTreeFindFile<cr>", "Find current file in file browser" }
  ["-"] = { "<cmd>Oil<cr>", "Find current file in file browser" },
  ["_"] = { "<cmd>Oil .<cr>", "File browser from project root" }
}, { mode = "n", noremap = true, silent = true })

-- Make nvim terminal more sane
which_key.register({
  ["<esc>"] = { [[<C-\><C-n>]], "Get to normal mode in terminal" },
  ["<M-[>"] = { "<esc>", "Send escape to terminal" },
  ["<C-v><Esc>"] = { "<esc>", "Send escape to terminal" },
  ["<C-h>"] = { [[<Cmd>wincmd h<CR>]], "Move one window left" },
  ["<C-j>"] = { [[<Cmd>wincmd j<CR>]], "Move one window down" },
  ["<C-k>"] = { [[<Cmd>wincmd k<CR>]], "Move one window up" },
  ["<C-l>"] = { [[<Cmd>wincmd l<CR>]], "Move one window right" },
  ["<C-v><C-h>"] = { [[<C-h>]], "Send c-h to terminal" },
  ["<C-v><C-j>"] = { [[<C-j>]], "Send c-j to terminal" },
  ["<C-v><C-k>"] = { [[<C-k>]], "Send c-k to terminal" },
  ["<C-v><C-l>"] = { [[<C-l>]], "Send c-l to terminal" }
}, { mode = "t", noremap = true, silent = true })

-- Setup tpope unimpaired-like forward/backward shortcuts reminders
which_key.register({
  ["[a"] = "Prev file arg",
  ["]a"] = "Next file arg",
  ["[b"] = { "<Cmd>BufferLineCyclePrev<CR>", "Prev buffer" },
  ["]b"] = { "<Cmd>BufferLineCycleNext<CR>", "Next buffer" },
  ["[c"] = "Prev git hunk",
  ["]c"] = "Next git hunk",
  ["[l"] = "Prev loclist item",
  ["]l"] = "Next loclist item",
  ["[q"] = "Prev quicklist item",
  ["]q"] = "Next quicklist item",
  ["[t"] = { "<Cmd>tabprevious<cr>", "Prev tab" },
  ["[T"] = { "<Cmd>tabprevious<cr>", "First tab" },
  ["]t"] = { "<Cmd>tabnext<cr>", "Next tab" },
  ["]T"] = { "<Cmd>tablast<cr>", "Last tab" },
  ["[n"] = "Prev conflict",
  ["]n"] = "Next conflict",
  ["[ "] = "Add blank line before",
  ["] "] = "Add blank line after",
  ["[e"] = "Swap line with previous",
  ["]e"] = "Swap line with next",
  ["[x"] = "XML encode",
  ["]x"] = "XML decode",
  ["[u"] = "URL encode",
  ["]u"] = "URL decode",
  ["[y"] = "C escape",
  ["]y"] = "C unescape",
  ["[d"] = { "<cmd>lua vim.diagnostic.goto_prev()<CR>", "Prev diagnostic" },
  ["]d"] = { "<cmd>lua vim.diagnostic.goto_next()<CR>", "Next diagnostic" },
  ["[1"] = { ":BufferLineGoToBuffer 1<CR>", "Go to buffer 1" },
  ["]1"] = { ":BufferLineGoToBuffer 1<CR>", "Go to buffer 1" },
  ["[2"] = { ":BufferLineGoToBuffer 2<CR>", "Go to buffer 2" },
  ["]2"] = { ":BufferLineGoToBuffer 2<CR>", "Go to buffer 2" },
  ["[3"] = { ":BufferLineGoToBuffer 3<CR>", "Go to buffer 3" },
  ["]3"] = { ":BufferLineGoToBuffer 3<CR>", "Go to buffer 3" },
  ["[4"] = { ":BufferLineGoToBuffer 4<CR>", "Go to buffer 4" },
  ["]4"] = { ":BufferLineGoToBuffer 4<CR>", "Go to buffer 4" },
  ["[5"] = { ":BufferLineGoToBuffer 5<CR>", "Go to buffer 5" },
  ["]5"] = { ":BufferLineGoToBuffer 5<CR>", "Go to buffer 5" },
  ["[6"] = { ":BufferLineGoToBuffer 6<CR>", "Go to buffer 6" },
  ["]6"] = { ":BufferLineGoToBuffer 6<CR>", "Go to buffer 6" },
  ["[7"] = { ":BufferLineGoToBuffer 7<CR>", "Go to buffer 7" },
  ["]7"] = { ":BufferLineGoToBuffer 7<CR>", "Go to buffer 7" },
  ["[8"] = { ":BufferLineGoToBuffer 8<CR>", "Go to buffer 8" },
  ["]8"] = { ":BufferLineGoToBuffer 8<CR>", "Go to buffer 8" },
  ["[9"] = { ":BufferLineGoToBuffer 9<CR>", "Go to buffer 9" },
  ["]9"] = { ":BufferLineGoToBuffer 9<CR>", "Go to buffer 9" },
  ["<S-h>"] = { ":BufferLineCyclePrev<CR>", "Go to next buffer" },
  ["<S-l>"] = { ":BufferLineCycleNext<CR>", "Go to prev buffer" },
  f = "Find next char x",
  F = "Find prev char x",
  t = "Find before prev char x",
  T = "Find before prev char x"
}, { mode = "n", silent = true })

which_key.register({
  f = "Find next char x",
  F = "Find prev char x",
  t = "Find before prev char x",
  T = "Find before prev char x"
}, { mode = "o", silent = true })

-- Flash mappings
-- Note: the regular mappings mess up surround plugin and various modes
-- Flash automatically enhances search (with / or ?) and char search (f, F, t, T)

-- ctrl-s will toggle that enhancement for search when in the midst of searching
which_key.register({
  ["<c-s>"] = { function() require("flash").toggle() end, "Toggle Flash Search" }
}, { mode = "c" })

-- ctrl-s will do general screen jump otherwise
which_key.register({
  ["<c-s>"] = {
    function() require("flash").jump({ jump = { autojump = true } }) end,
    "Flash Search"
  },
  ["<leader>fj"] = {
    function() require("flash").jump({ jump = { autojump = true } }) end,
    "Jump on screen"
  }
}, { mode = "n" })

-- Replace vim-visual plugin * and # search of word under cursor
-- The \V tells vim to not treat any special chars as special (except backslash)
-- <cname> won't include a backslash in the word
-- The \< and \> mark word start and end so `*` search for the exact word as a word
-- and `gv` search for the word even if within other words
-- which_key.register({}, { mode = "n" })

-- Start visual mode and then adjust selection by treesitter nodes with s
-- so `vs` or `vjjs` or whatever should allow selecting a treesitter node
-- or expanding/contracting it with `;` and `,`
which_key.register({
  ["<c-s>"] = { require("flash").jump, "Visual Extend via Flash" },
  r = { require("flash").treesitter, "Visual Extend to Treesitter block" }
}, { mode = "x" })
