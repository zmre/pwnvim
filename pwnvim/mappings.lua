local M = {}

local startswith = function(haystack, prefix)
  return string.sub(string.lower(haystack), 1, #prefix) == string.lower(prefix)
end

local addcommand = function(rhs)
  -- the string.sub trick avoids searching the entire string to figure out startswith; see https://programming-idioms.org/idiom/96/check-string-prefix/1882/lua
  -- purpose here is to add the "<cmd>" prefix and "<cr>" as best practice, but only if "<cmd>" wasn't already provided
  if type(rhs) == "string" and not startswith(rhs, "<cmd>") and not startswith(rhs, ":") and not startswith(rhs, "<plug>") then
    rhs = ("<cmd>%s<cr>"):format(rhs)
  end
  return rhs
end
M.map = function(mode, lhs, rhs, desc, opts)
  opts = opts or { silent = true, noremap = true }
  opts["desc"] = desc or ""
  vim.keymap.set(
    mode or "n", -- can also be a map like {"n", "c"}
    lhs,         -- key to bind
    rhs,         -- string or function
    opts
  )
end
M.mapn = function(lhs, rhs, desc, opts)
  M.map("n", lhs, addcommand(rhs), desc, opts)
end
M.mapv = function(lhs, rhs, desc, opts)
  M.map("v", lhs, addcommand(rhs), desc, opts)
end
M.mapnv = function(lhs, rhs, desc, opts)
  M.map({ "n", "v" }, lhs, addcommand(rhs), desc, opts)
end
M.mapic = function(lhs, rhs, desc, opts)
  -- in insert/command mode, don't assume <cmd> as we might be using keystrokes in insert mode on purpose
  M.map({ "i", "c" }, lhs, rhs, desc, opts)
end
M.mapnvic = function(lhs, rhs, desc, opts)
  M.map({ "n", "v", "i", "c" }, lhs, addcommand(rhs), desc, opts)
end
M.mapi = function(lhs, rhs, desc, opts)
  -- in insert mode, don't assume <cmd> as we might be using keystrokes in insert mode on purpose
  M.map("i", lhs, rhs, desc, opts)
end
M.mapox = function(lhs, rhs, desc, opts)
  -- in operator pending mode, don't assume <cmd> as we might be using keystrokes in insert mode on purpose
  M.map({ "o", "x" }, lhs, rhs, desc, opts)
end
M.mapt = function(lhs, rhs, desc, opts)
  M.map("t", lhs, addcommand(rhs), desc, opts)
end
M.mapleadern = function(lhs, rhs, desc, opts)
  M.mapn("<leader>" .. lhs, rhs, desc, opts)
end
M.mapleaderv = function(lhs, rhs, desc, opts)
  M.mapv("<leader>" .. lhs, rhs, desc, opts)
end
M.mapleadernv = function(lhs, rhs, desc, opts)
  M.mapnv("<leader>" .. lhs, rhs, desc, opts)
end

M.makelocalmap = function(bufnr, mapfunc)
  return function(lhs, rhs, desc, opts)
    opts = opts or { silent = true, noremap = true }
    opts["buffer"] = bufnr
    mapfunc(lhs, rhs, desc, opts)
  end
end

M.config = function()
  -- We use which-key in mappings, which is loaded before plugins, so set up here
  local which_key = require("which-key")
  local enter = vim.api.nvim_replace_termcodes("<cr>", true, false, true)


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
    ["<leader>gt"] = { name = "+git toggle" },
    ["<leader>gw"] = { name = "+git workspace" },
    ["<leader>h"] = { name = "+hunk" },
    ["<leader>i"] = { name = "+indent" },
    ["<leader>l"] = { name = "+lsp" },
    ["<leader>ls"] = { name = "+symbols" },
    ["<leader>n"] = { name = "+notes" },
    ["<leader>t"] = { name = "+tasks" },
  })

  -- This file is for mappings that will work regardless of filetype. Always available.

  -- ALL MODE (EXCEPT OPERATOR) MAPPINGS
  -- Make F1 act like escape for accidental hits
  M.map({ "n", "v", "i", "c" }, "<F1>", "<Esc>", "Escape")
  -- Make F2 bring up a file browser
  M.mapnvic("<F2>", "Oil .", "Toggle file browser")
  -- Use F3 for a quick grep with Trouble to show results
  M.mapnvic("<F3>", function()
    vim.ui.input({ prompt = "Regex: " }, function(needle)
      vim.cmd("lgrep -i " .. needle)
      require("trouble").toggle({ mode = "loclist", position = "bottom" })
    end)
  end)
  -- Make F4 toggle invisible characters (locally)
  M.mapnvic("<F4>", function()
    if vim.opt_local.list:get() then
      vim.opt_local.list = false
      vim.opt_local.conceallevel = 2
      vim.cmd("IBLEnable")
    else
      vim.opt_local.list = true
      vim.opt_local.conceallevel = 0
      vim.cmd("IBLDisable") -- indent lines hide some chars like tab
    end
  end, "Toggle show invisible chars")
  -- Make ctrl-p open a file finder
  -- When using ctrl-p, screen out media files that we probably don't want
  -- to open in vim. And if we really want, then we can use ,ff
  M.mapnvic("<c-p>", require("telescope.builtin").find_files, "Find files")
  M.mapnvic("<F9>", "TZAtaraxis", "Focus mode")
  -- Make F10 quicklook. Not sure how to do this best in linux so mac only for now
  M.mapnvic("<F10>", 'silent !qlmanage -p "%"', "Quicklook (mac)")
  M.mapnvic("<F12>", 'syntax sync fromstart', "Restart highlighting")
  -- Pane navigation integrated with tmux
  M.mapnvic("<c-h>", "TmuxNavigateLeft", "Pane left")
  M.mapnvic("<c-j>", "TmuxNavigateDown", "Pane down")
  M.mapnvic("<c-k>", "TmuxNavigateUp", "Pane up")
  M.mapnvic("<c-l>", "TmuxNavigateRight", "Pane right")
  M.mapnvic("<D-w>", "Bdelete", "Close buffer")
  M.mapnvic("<A-w>", "Bdelete", "Close buffer")
  M.mapnvic("<M-w>", "Bdelete", "Close buffer")
  M.mapnvic("<D-n>", "enew", "New buffer")
  M.mapnvic("<D-t>", "tabnew", "New tab")
  M.mapnvic("<D-s>", "write", "Save buffer")
  M.mapnvic("<D-q>", "quit", "Quit")
  -- Magic buffer-picking mode
  M.mapnvic("<M-b>", "BufferLinePick", "Pick buffer by letter")

  -- Copy and paste ops mainly for neovide / gui apps
  if require("pwnvim.options").isGuiRunning() then
    M.mapn("<D-v>", 'normal "+p', "Paste")
    M.mapv("<D-c>", 'normal "+ygv', "Copy")
    M.mapv("<D-v>", 'normal "+p', "Paste")
    M.mapic("<D-v>", '<c-r>+', "Paste", { noremap = true, silent = false })
    M.map("t", "<D-v>", '<C-\\><C-n>"+pa', "Paste")

    -- Adjust font sizes
    local function get_font()
      local guifont = vim.api.nvim_get_option("guifont")
      local curr_font = {}
      curr_font.name = guifont:match("^(.*)%:")
      curr_font.size = tonumber(guifont:match("%:h(%d+)"))
      return curr_font
    end
    local function change_font(name, size)
      vim.opt.guifont = name .. ":h" .. size
    end
    local function increase_font()
      local curr_font = get_font()
      local new_size = tostring(curr_font.size + 1)
      change_font(curr_font.name, new_size)
    end
    local function decrease_font()
      local curr_font = get_font()
      local new_size = tostring(curr_font.size - 1)
      change_font(curr_font.name, new_size)
    end
    local function reset_font()
      local curr_font = get_font()
      local new_size = require("pwnvim.options").defaultFontSize()
      change_font(curr_font.name, new_size)
    end
    M.mapnvic("<D-=>", increase_font, "Increase font size")
    M.mapnvic("<D-->", decrease_font, "Decrease font size")
    M.mapnvic("<D-0>", reset_font, "Reset font size")
    M.mapnvic("<C-=>", increase_font, "Increase font size")
    M.mapnvic("<C-->", decrease_font, "Decrease font size")
    M.mapnvic("<C-0>", reset_font, "Reset font size")
  end

  -- NORMAL MODE ONLY MAPPINGS
  M.map("n", "<A-up>", "[e", "Move line up")
  M.map("n", "<A-down>", "]e", "Move line down")
  M.mapn("zi", function() -- override default fold toggle behavior to fix fold columns and scan
    if vim.wo.foldenable then
      -- Disable completely
      vim.wo.foldenable = false
      vim.wo.foldmethod =
      "manual" -- seeing weird things where folds are off, but expression being run anyway. this should fix.
      vim.wo.foldcolumn = "0"
    else
      vim.wo.foldenable = true
      -- TODO: maybe save this value above and set back to last value?
      vim.wo.foldmethod = "expr"
      vim.wo.foldcolumn = "auto:4"
      vim.cmd("normal zx") -- reset folds
    end
  end, "Toggle folding"
  )
  M.map("n", "<F8>", '"=strftime("%Y-%m-%d")<CR>P', "Insert date")
  M.mapic("<F8>", '<C-R>=strftime("%Y-%m-%d")<CR>', "Insert date at cursor", { noremap = true, silent = false })
  M.map("n", "<D-[>", "<<", "Outdent")
  M.map("n", "<D-]>", ">>", "Indent")
  M.map("n", "n", "nzzzv", "Center search hits vertically on screen and expand folds if hit is inside")
  M.map("n", "N", "Nzzzv", "Center search hits vertically on screen and expand folds if hit is inside")
  M.map("n", "<c-d>", "<c-d>zz", "Half scroll down keep cursor center screen")
  M.map("n", "<c-u>", "<c-u>zz", "Half scroll up keep cursor center screen")
  -- gx is a built-in to open URLs under the cursor, but when
  -- not using netrw, it doesn't work right. Or maybe it's just me
  -- but anyway this command works great.
  -- /Users/pwalsh/Documents/md2rtf-style.html
  -- ../README.md
  -- ~/Desktop/Screen Shot 2018-04-06 at 5.19.32 PM.png
  -- [abc](https://github.com/adsr/mle/commit/e4dc4314b02a324701d9ae9873461d34cce041e5.patch)
  M.mapn("gx", ':silent !open "<c-r><c-f>" || xdg-open "<c-r><c-f>"<CR>', "Launch URL or path")
  M.mapn("*",
    function()
      local text = "\\<" .. string.gsub(vim.fn.expand("<cword>"), "/", "\\/") ..
          "\\>"
      -- Can't find a way to have flash jump keep going past what's visible on the screen
      vim.api.nvim_feedkeys("/\\V" .. text .. enter, 'n', false)
    end, "Find word under cursor forward"
  )
  M.mapn("#",
    function()
      local text = "\\<" .. string.gsub(vim.fn.expand("<cword>"), "?", "\\?") ..
          "\\>"
      vim.api.nvim_feedkeys("?\\V" .. text .. enter, 'n', false)
    end, "Find word under cursor backward"
  )
  M.mapn("g*",
    function()
      -- Same as above, but don't qualify as full word only
      local text = string.gsub(vim.fn.expand("<cword>"), "/", "\\/")
      vim.api.nvim_feedkeys("/\\V" .. text .. enter, 'n', false)
    end, "Find partial word under cursor forward"
  )
  M.mapn("g#",
    function()
      -- Same as above, but don't qualify as full word only
      local text = string.gsub(vim.fn.expand("<cword>"), "?", "\\?")
      vim.api.nvim_feedkeys("?" .. text .. enter, 'n', false)
      -- vim.cmd("?\\V" .. text) -- works, but doesn't trigger flash
    end, "Find partial word under cursor backward"
  )
  M.map("n", "<space>", [[@=(foldlevel('.')?'za':"\<Space>")<CR>]], "Toggle folds if enabled")


  M.mapn("<leader>p", 'normal "*p', "Paste")
  M.mapn("[0", "BufferLinePick", "Pick buffer by letter")
  M.mapn("]0", "BufferLinePick", "Pick buffer by letter")

  M.map("v", "gx", '"0y:silent !open "<c-r>0" || xdg-open "<c-r>0"<cr>gv', "Launch URL or path")
  -- When pasting over selected text, keep original register value
  M.map("v", "p", '"_dP', "Paste over selected no store register")
  -- keep visual block so you can move things repeatedly
  M.map("v", "<", "<gv", "Outdent and preserve block")
  M.map("v", ">", ">gv", "Indent and preserve block")
  M.mapi("<D-[>", "<C-d>", "Outdent")
  M.mapi("<D-]>", "<C-t>", "Indent")
  M.map("v", "<D-[>", "<gv", "Outdent and preserve block")
  M.map("v", "<D-]>", ">gv", "Indent and preserve block")
  M.map("v", "<A-Up>", "[egv", "Move line up preserve block")
  M.map("v", "<A-Down>", "]egv", "Move line down preserve block")

  -- emacs bindings to jump around in lines
  M.mapi("<C-e>", "<C-o>A", "Jump to end of line")
  M.mapi("<C-a>", "<C-o>I", "Jump to start of line")

  -- Send cursor somewhere on screen and pick a text object from it.
  -- Uses operator pending mode so you start it with something like `yr` then
  -- after jump pick the text object like `iw` and you'll copy that other thing
  -- and be back where you were at the start.
  M.map("o", "R", require("flash").remote, "Remote operation via Flash")
  M.map("o", "<c-s>", require("flash").jump, "Flash select")
  M.map("o", "r", require("flash").treesitter, "Flash select")
  --
  -- Move visually selected lines up and down
  -- vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
  -- vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

  M.mapleadernv("e", "Oil", "Find current file in file browser")
  M.mapleadernv("/", "nohlsearch", "Clear highlight")
  M.mapleadernv("x", "Bdelete!", "Close buffer")
  M.mapleadernv("q", "TroubleToggle", "Toggle trouble quicklist")
  M.mapleadernv("fb",
    function() require('telescope.builtin').buffers(require('telescope.themes').get_dropdown { previewer = false }) end,
    "Buffers")
  M.mapleadernv("fc", function() require('telescope.builtin').live_grep({ search_dirs = { vim.fn.expand('%:p:h') } }) end,
    "Grep from dir of current file")
  M.mapleadernv("fd", require('telescope.builtin').lsp_document_symbols, "Document symbols search")
  M.mapleadernv("ff", require('telescope.builtin').find_files, "Files")
  M.mapleadernv("fg", require('telescope.builtin').live_grep, "Grep")
  M.mapleadernv("fh", function()
    require('telescope.builtin').oldfiles { only_cwd = true }
  end, "History local")
  M.mapleadernv("fk", require('telescope.builtin').keymaps, "Keymaps")
  M.mapleadernv("fl", require('telescope.builtin').loclist, "Loclist")
  M.mapleadernv("fn", function() require('zk.commands').get("ZkNotes")({ sort = { 'modified' } }) end, "Find notes")
  M.mapleadernv("fo", require('telescope.builtin').oldfiles, "Old file history global")
  M.mapleadernv("fp", require("telescope").extensions.projects.projects, "Projects")
  M.mapleadernv("fq", require('telescope.builtin').quickfix, "Quickfix")
  -- ,fs mapping done inside lsp attach functions
  M.mapleadernv("ft",
    'lua require(\'telescope.builtin\').grep_string{search = "^\\\\s*[*-] \\\\[ \\\\]", previewer = false, glob_pattern = "*.md", use_regex = true, disable_coordinates=true}',
    "Todos")
  M.mapleadernv("fz", function()
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
  end, "Open folder")

  -- Quickly change indent defaults in a file
  M.mapleadernv("i1", require('pwnvim.options').tabindent, "Tab")
  M.mapleadernv("i2", require('pwnvim.options').twospaceindent, "Two Space")
  M.mapleadernv("i4", require('pwnvim.options').fourspaceindent, "Four Space")
  M.mapleadernv("ir", "%retab!", "Change existing indent to current with retab")

  -- Git bindings
  -- Browse git things
  M.mapleadernv("gs", require('telescope.builtin').git_status, "Status")
  M.mapleadernv("gb", require('telescope.builtin').git_branches, "Branches")
  M.mapleadernv("gc", require('telescope.builtin').git_commits, "Commits")
  -- Worktree stuff
  M.mapleadernv("gws", require('telescope').extensions.git_worktree.git_worktrees, "Switch worktree")
  M.mapleadernv("gwn", require('telescope').extensions.git_worktree.create_git_worktree, "New worktree")
  -- Bunch more will be mapped locally with gitsigns when it loads. See ./gitsigns.lua


  -- Set cwd to current file's dir
  M.mapleadernv("lcd", "lcd %:h", "Change local dir to path of current file")
  M.mapleadernv("cd", "cd %:h", "Change global dir to path of current file")

  -- note shortcuts
  M.mapleadernv("nd", require("pwnvim.markdown").newDailyNote, "New diary")
  M.mapleadern("ne", '!mv "<cfile>" "<c-r>=expand(\'%:p:h\')<cr>/"', "Embed file moving to current file's folder")
  M.mapleaderv("ne", 'normal "0y:!mv "<c-r>0" "<c-r>=expand(\'%:p:h\')<cr>/"',
    "Embed file moving to current file's folder")
  M.mapleadern("nf", "ZkNotes { sort = { 'modified' }}", "Find")
  M.map({ "v" }, "<leader>nf", ":'<,'>ZkMatch<CR>", "Find Selected")

  M.mapleadernv("ng", require('pwnvim.plugins').grammar_check, "Check Grammar")
  M.mapleadernv("nh", "edit ~/Notes/Notes/HotSheet.md", "Open HotSheet")
  M.mapleadernv("nm", require("pwnvim.markdown").newMeetingNote, "New meeting")
  M.mapleadernv("nn", require("pwnvim.markdown").newGeneralNote, "New")
  M.mapleadernv("nt", "ZkTags", "Open by tag")

  -- note insert shortcuts
  M.mapleadernv("nic",
    "r!/opt/homebrew/bin/icalBuddy --bullet '* ' --timeFormat '\\%H:\\%M' --dateFormat '' --noPropNames --noCalendarNames --excludeAllDayEvents --includeCals 'IC - Work' --includeEventProps datetime,title,attendees,location --propertyOrder datetime,title,attendees,location --propertySeparators '| |\\n    * |\\n    * | |' eventsToday",
    "Insert today's calendar")
  M.mapleadernv("nio", "r!gtm-okr goals", "Insert OKRs")
  M.mapleadernv("nij",
    "r!( (curl -s https://icanhazdadjoke.com/ | grep '\\\"subtitle\\\"') || curl -s https://icanhazdadjoke.com/ ) | sed 's/<[^>]*>//g' | sed -z 's/\\n/ /'",
    "Insert joke")
  -- in open note (defined in plugins.lua as local-only shortcuts) via LSPs:
  -- ,np: new peer note
  -- ,nl: show outbound links
  -- ,nr: show outbound links
  -- ,ni: info preview

  M.mapleadern("sd", [[echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')]], "Debug syntax files")

  M.mapn("<D-j>", "normal gj", "Down screen line")
  M.mapn("<D-k>", "normal gk", "Up screen line")
  M.mapn("<D-4>", "normal g$", "End of screen line")
  M.mapn("<D-6>", "normal g^", "Beginning of screen line")
  -- Visually select the text that was last edited/pasted
  -- Similar to gv but works after paste
  M.map({ "n" }, "gV", "`[v`]", "Visually select the text last edited (after paste)")
  M.map({ "n" }, "Y", "y$", "Yank to end of line")
  M.mapnv("-", "Oil", "Find current file in file browser")
  M.mapnv("_", "Oil .", "File browser from project root")

  -- TODO Have ctrl-l continue to do what it did, but also temp clear search match highlighting

  -- Make nvim terminal more sane
  M.map({ "t" }, "<esc>", [[<C-\><C-n>]], "Get to normal mode in terminal")
  M.map({ "t" }, "<M-[>", "<esc>", "Send escape to terminal")
  M.map({ "t" }, "<C-v><Esc>", "<esc>", "Send escape to terminal")
  M.mapt("<c-j>", "wincmd j", "Move one window down")
  M.mapt("<c-h>", "wincmd h", "Move one window left")
  M.mapt("<c-k>", "wincmd k", "Move one window up")
  M.mapt("<c-l>", "wincmd l", "Move one window right")
  M.map("t", "<c-v><c-j>", "<c-j>", "Send c-j to terminal")
  M.map("t", "<c-v><c-h>", "<c-h>", "Send c-h to terminal")
  M.map("t", "<c-v><c-k>", "<c-k>", "Send c-k to terminal")
  M.map("t", "<c-v><c-l>", "<c-l>", "Send c-l to terminal")


  -- Setup tpope unimpaired-like forward/backward shortcuts reminders
  which_key.register({
    ["[A"] = "First file arg",
    ["[a"] = "Prev file arg",
    ["]a"] = "Next file arg",
    ["]A"] = "Last file arg",
    ["[B"] = "First buffer",
    ["]B"] = "Last buffer",
    ["[b"] = { "<Cmd>BufferLineCyclePrev<CR>", "Prev buffer" },
    ["]b"] = { "<Cmd>BufferLineCycleNext<CR>", "Next buffer" },
    ["[c"] = "Prev git hunk",
    ["]c"] = "Next git hunk",
    ["[f"] = "Prev file in dir of cur file",
    ["]f"] = "Next file in dir of cur file",
    ["[L"] = "First loclist item",
    ["[l"] = "Prev loclist item",
    ["]l"] = "Next loclist item",
    ["]L"] = "Last loclist item",
    ["[Q"] = "First quicklist item",
    ["[q"] = "Prev quicklist item",
    ["]q"] = "Next quicklist item",
    ["]Q"] = "Last quicklist item",
    ["]p"] = "Put below",
    ["]P"] = "Put below",
    ["[t"] = { "<Cmd>tabprevious<cr>", "Prev tab" },
    ["[T"] = { "<Cmd>tabfirst<cr>", "First tab" },
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
    ["[d"] = { vim.diagnostic.goto_prev, "Prev diagnostic" },
    ["]d"] = { vim.diagnostic.goto_next, "Next diagnostic" },
    ["[1"] = { "<cmd>BufferLineGoToBuffer 1<CR>", "Go to buffer 1" },
    ["]1"] = { "<cmd>BufferLineGoToBuffer 1<CR>", "Go to buffer 1" },
    ["[2"] = { "<cmd>BufferLineGoToBuffer 2<CR>", "Go to buffer 2" },
    ["]2"] = { "<cmd>BufferLineGoToBuffer 2<CR>", "Go to buffer 2" },
    ["[3"] = { "<cmd>BufferLineGoToBuffer 3<CR>", "Go to buffer 3" },
    ["]3"] = { "<cmd>BufferLineGoToBuffer 3<CR>", "Go to buffer 3" },
    ["[4"] = { "<cmd>BufferLineGoToBuffer 4<CR>", "Go to buffer 4" },
    ["]4"] = { "<cmd>BufferLineGoToBuffer 4<CR>", "Go to buffer 4" },
    ["[5"] = { "<cmd>BufferLineGoToBuffer 5<CR>", "Go to buffer 5" },
    ["]5"] = { "<cmd>BufferLineGoToBuffer 5<CR>", "Go to buffer 5" },
    ["[6"] = { "<cmd>BufferLineGoToBuffer 6<CR>", "Go to buffer 6" },
    ["]6"] = { "<cmd>BufferLineGoToBuffer 6<CR>", "Go to buffer 6" },
    ["[7"] = { "<cmd>BufferLineGoToBuffer 7<CR>", "Go to buffer 7" },
    ["]7"] = { "<cmd>BufferLineGoToBuffer 7<CR>", "Go to buffer 7" },
    ["[8"] = { "<cmd>BufferLineGoToBuffer 8<CR>", "Go to buffer 8" },
    ["]8"] = { "<cmd>BufferLineGoToBuffer 8<CR>", "Go to buffer 8" },
    ["[9"] = { "<cmd>BufferLineGoToBuffer 9<CR>", "Go to buffer 9" },
    ["]9"] = { "<cmd>BufferLineGoToBuffer 9<CR>", "Go to buffer 9" },
    ["<S-h>"] = { "<cmd>BufferLineCyclePrev<CR>", "Go to next buffer" },
    ["<S-l>"] = { "<cmd>BufferLineCycleNext<CR>", "Go to prev buffer" },
  }, { mode = "n", silent = true })


  -- Flash mappings
  -- Note: the regular mappings mess up surround plugin and various modes
  -- Flash automatically enhances search (with / or ?) and char search (f, F, t, T)

  -- ctrl-s will toggle that enhancement for search when in the midst of searching
  which_key.register({
    ["<c-s>"] = { require("flash").toggle, "Toggle Flash Search" }
  }, { mode = "c" })

  -- Start visual mode and then adjust selection by treesitter nodes with s
  -- so `vs` or `vjjs` or whatever should allow selecting a treesitter node
  -- or expanding/contracting it with `;` and `,`
  -- ctrl-s will do general screen jump otherwise
  M.mapn("<c-s>", function() require("flash").jump({ jump = { autojump = true } }) end, "Flash Search")
  M.mapleadern("fj", function() require("flash").jump({ jump = { autojump = true } }) end, "Jump on screen")
  M.mapox("<c-s>", require("flash").jump, "Visual Extend via Flash")
  M.mapox("r", require("flash").treesitter, "Visual Extend to Treesitter block")
end

return M
