-- We use which-key in mappings, which is loaded before plugins, so set up here
local which_key = require("which-key")
local enter = vim.api.nvim_replace_termcodes("<cr>", true, false, true)
which_key.setup({
  plugins = {
    marks = true, -- shows a list of your marks on ' and `
    registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
    spelling = {
      enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      suggestions = 20 -- how many suggestions should be shown in the list?
    },
    -- the presets plugin, adds help for a bunch of default keybindings in Neovim
    -- No actual key bindings are created
    presets = {
      operators = true, -- adds help for operators like d, y, ... and registers them for motion / text object completion
      motions = false, -- adds help for motions
      text_objects = true, -- help for text objects triggered after entering an operator
      windows = true, -- default bindings on <c-w>
      nav = true, -- misc bindings to work with windows
      z = true, -- bindings for folds, spelling and others prefixed with z
      g = true -- bindings for prefixed with g
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

-- This file is for mappings that will work regardless of filetype. Always available.

-- ALL MODE (EXCEPT OPERATOR) MAPPINGS
which_key.register({
  -- Make F1 act like escape for accidental hits
  ["#1"] = {"<Esc>", "Escape"},
  -- Make F2 bring up a file browser
  ["#2"] = {"<cmd>NvimTreeToggle<cr>", "Toggle file browser"},
  ["#4"] = {
    function() vim.opt.list = not (vim.opt.list:get()) end,
    "Toggle show invisible chars"
  },
  -- Make ctrl-p open a file finder
  -- When using ctrl-p, screen out media files that we probably don't want
  -- to open in vim. And if we really want, then we can use ,ff
  ["<c-p>"] = {"<cmd>silent Telescope find_files<cr>", "Find files"},
  ["#9"] = {'<cmd>TZAtaraxis<cr>', "Focus mode"},
  -- Make F10 quicklook. Not sure how to do this best in linux so mac only for now
  ["#10"] = {'<cmd>silent !qlmanage -p "%"<cr>', "Quicklook (mac)"},
  ["#12"] = {'<cmd>syntax sync fromstart<cr>', "Restart highlighting"},
  -- Pane navigation integrated with tmux
  ["<c-h>"] = {"<cmd>TmuxNavigateLeft<cr>", "Pane left"},
  ["<c-j>"] = {"<cmd>TmuxNavigateDown<cr>", "Pane down"},
  ["<c-k>"] = {"<cmd>TmuxNavigateUp<cr>", "Pane up"},
  ["<c-l>"] = {"<cmd>TmuxNavigateRight<cr>", "Pane right"},
  ["<D-g>"] = {'"*p', "paste"},
  ["<D-v>"] = {'<cmd>normal "*p<cr>', "paste"},
  ["<leader>p"] = {'<cmd>normal "*p<cr>', "paste"},
  ["<D-w>"] = {"<cmd>Bdelete<CR>", "Close buffer"},
  ["<A-w>"] = {"<cmd>Bdelete<CR>", "Close buffer"},
  ["<M-w>"] = {"<cmd>Bdelete<CR>", "Close buffer"},
  ["<D-n>"] = {"<cmd>enew<cr>", "New buffer"},
  ["<D-t>"] = {"<cmd>tabnew<cr>", "New tab"},
  ["<D-s>"] = {"<cmd>write<cr>", "Save buffer"},
  ["<D-q>"] = {"<cmd>quit<cr>", "Quit"},
  -- Magic buffer-picking mode
  ["<M-b>"] = {"<cmd>BufferLinePick<CR>", "Pick buffer by letter"},
  ["[0"] = {"<cmd>BufferLinePick<CR>", "Pick buffer by letter"},
  ["]0"] = {"<cmd>BufferLinePick<CR>", "Pick buffer by letter"}
}, {mode = {"n", "v", "i", "c"}, noremap = true, silent = true})

-- NORMAL AND VISUAL MAPPINGS
-- which_key.register({
-- },{mode={"n","v"}})

-- NORMAL AND VISUAL AND COMMAND MAPPINGS

-- NORMAL MODE ONLY MAPPINGS
which_key.register({
  ["A-Up"] = {"[e", "Move line up"},
  ["A-Down"] = {"]e", "Move line down"},
  ["zi"] = {
    function() -- override default fold toggle behavior to fix fold columns and scan
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
  },
  ["#8"] = {'"=strftime("%Y-%m-%d")<CR>P', "Insert date"},
  ["<D-[>"] = {'<<', "Outdent"},
  ["<D-]>"] = {'>>', "Indent"},
  n = {
    "nzzzv",
    "Center search hits vertically on screen and expand folds if hit is inside"
  },
  N = {
    "Nzzzv",
    "Center search hits vertically on screen and expand folds if hit is inside"
  },
  ["<c-d>"] = {"<c-d>zz"},
  ["<c-u>"] = {"<c-u>zz"},
  -- gx is a built-in to open URLs under the cursor, but when
  -- not using netrw, it doesn't work right. Or maybe it's just me
  -- but anyway this command works great.
  -- /Users/pwalsh/Documents/md2rtf-style.html
  -- ../README.md
  -- ~/Desktop/Screen Shot 2018-04-06 at 5.19.32 PM.png
  -- [abc](https://github.com/adsr/mle/commit/e4dc4314b02a324701d9ae9873461d34cce041e5.patch)
  ["gx"] = {
    ':silent !open "<c-r><c-f>" || xdg-open "<c-r><c-f>"<cr>',
    "Launch URL or path"
  },
  ["*"] = {
    function()
      local text = "\\<" .. string.gsub(vim.fn.expand("<cword>"), "/", "\\/") ..
                       "\\>"
      -- vim.cmd("/\\V" .. text) -- works, but doesn't trigger flash
      vim.api.nvim_feedkeys("/\\V" .. text .. enter, 'n', false)
      -- Can't find a way to have flash jump keep going past what's visible on the screen
      -- require("flash").jump({
      --   pattern = vim.fn.expand("<cword>"),
      --   search = {forward = true, wrap = false, multi_window = false},
      --   jump = {autojump=true}
      -- })
    end, "Find word under cursor forward"
  },
  ["#"] = {
    function()
      local text = "\\<" .. string.gsub(vim.fn.expand("<cword>"), "?", "\\?") ..
                       "\\>"
      vim.api.nvim_feedkeys("?\\V" .. text .. enter, 'n', false)
      -- vim.cmd("?\\V" .. text) -- works, but doesn't trigger flash
    end, "Find word under cursor backward"
  },
  ["g*"] = {
    function()
      -- Same as above, but don't qualify as full word only
      local text = string.gsub(vim.fn.expand("<cword>"), "/", "\\/")
      vim.api.nvim_feedkeys("/\\V" .. text .. enter, 'n', false)
      -- vim.cmd("/\\V" .. text) -- works, but doesn't trigger flash
    end, "Find partial word under cursor forward"
  },
  ["g#"] = {
    function()
      -- Same as above, but don't qualify as full word only
      local text = string.gsub(vim.fn.expand("<cword>"), "?", "\\?")
      vim.api.nvim_feedkeys("?" .. text .. enter, 'n', false)
      -- vim.cmd("?\\V" .. text) -- works, but doesn't trigger flash
    end, "Find partial word under cursor backward"
  },
  ["<space>"] = {
    [[@=(foldlevel('.')?'za':"\<Space>")<CR>]], "Toggle folds if enabled"
  },
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
  }
}, {mode = "n"})

-- VISUAL MODE ONLY MAPPINGS
which_key.register({
  ["gx"] = {
    '"0y:silent !open "<c-r>0" || xdg-open "<c-r>0"<cr>gv', "Launch URL or path"
  },
  -- When pasting over selected text, keep original register value
  ["p"] = {'"_dP', "Paste over selected no store register"},
  -- keep visual block so you can move things repeatedly
  ["<"] = {"<gv", "Outdent and preserve block"},
  [">"] = {">gv", "Indent and preserve block"},
  ["<D-[>"] = {"<gv", "Outdent and preserve block"},
  ["<D-]>"] = {">gv", "Indent and preserve block"},
  ["A-Up"] = {"[egv", "Move line up preserve block"},
  ["A-Down"] = {"]egv", "Move line down preserve block"}
}, {mode = "v"})

-- OPERATOR PENDING MODE ONLY MAPPINGS

-- INSERT MODE ONLY MAPPINGS
which_key.register({
  -- emacs bindings to jump around in lines
  ["<C-e>"] = {"<C-o>A", "Jump to end of line"},
  ["<C-a>"] = {"<C-o>I", "Jump to start of line"},
  ["<D-[>"] = {"<C-o><<", "Outdent"},
  ["<D-]>"] = {"<C-o>>>", "Indent"}
}, {mode = "i"})

-- COMMAND AND INSERT MAPPINGS
which_key.register({
  ["%%"] = {"<c-r>=expand('%:p:h')<cr>/", "Insert current folder for file"},
  ["#8"] = {'<C-R>=strftime("%Y-%m-%d")<CR>', "Insert date at cursor"}
}, {mode = {"c", "i"}, noremap = true, silent = false})

-- COMMAND MODE ONLY MAPPINGS
which_key.register({
  -- Send cursor somewhere on screen and pick a text object from it.
  -- Uses operator pending mode so you start it with something like `yr` then
  -- after jump pick the text object like `iw` and you'll copy that other thing
  -- and be back where you were at the start.
  R = {function() require("flash").remote() end, "Remote operation via Flash"},
  ["<c-s>"] = {function() require("flash").jump() end, "Flash select"},
  r = {
    function() require("flash").treesitter() end, "Flash select via Treesitter"
  }
}, {mode = "o"})

local options = {}

-- Move visually selected lines up and down
-- vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
-- vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

local leader_mappings = {
  e = {"<cmd>NvimTreeToggle<cr>", "Explorer"},
  ["/"] = {"<cmd>nohlsearch<CR>", "Clear Highlight"},
  x = {"<cmd>Bdelete!<CR>", "Close Buffer"},
  q = {
    [["<cmd>".(get(getqflist({"winid": 1}), "winid") != 0? "cclose" : "botright copen")."<cr>"]],
    "Toggle Quicklist"
  },
  f = {
    name = "Find",
    f = {"<cmd>lua require('telescope.builtin').find_files()<CR>", "Files"},
    g = {"<cmd>lua require('telescope.builtin').live_grep()<CR>", "Grep"},
    b = {
      "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<cr>",
      "Buffers"
    },
    d = {
      "<cmd>silent Telescope lsp_document_symbols<cr>",
      "Document symbols search"
    },
    h = {"<cmd>lua require('telescope.builtin').oldfiles()<cr>", "History"},
    q = {"<cmd>lua require('telescope.builtin').quickfix()<cr>", "Quickfix"},
    l = {"<cmd>lua require('telescope.builtin').loclist()<cr>", "Loclist"},
    p = {"<cmd>Telescope projects<cr>", "Projects"},
    k = {"<cmd>Telescope keymaps<cr>", "Keymaps"},
    t = {
      '<cmd>lua require(\'telescope.builtin\').grep_string{search = "^\\\\s*[*-] \\\\[ \\\\]", previewer = false, glob_pattern = "*.md", use_regex = true, disable_coordinates=true}<cr>',
      "Todos"
    },
    n = {"<Cmd>ZkNotes { match = {vim.fn.input('Search: ')} }<CR>", "Find"}
  },
  -- Quickly change indent defaults in a file
  i = {
    name = "Indent",
    ["1"] = {"<cmd>lua require('pwnvim.options').tabindent()<CR>", "Tab"},
    ["2"] = {
      "<cmd>lua require('pwnvim.options').twospaceindent()<CR>", "Two Space"
    },
    ["4"] = {
      "<cmd>lua require('pwnvim.options').fourspaceindent()<CR>", "Four Space"
    },
    r = {"<cmd>%retab!<cr>", "Change existing indent to current with retab"}
  },
  g = {
    name = "Git",
    s = {"<cmd>lua require('telescope.builtin').git_status()<cr>", "Status"},
    b = {"<cmd>lua require('telescope.builtin').git_branches()<cr>", "Branches"},
    c = {"<cmd>lua require('telescope.builtin').git_commits()<cr>", "Commits"},
    h = {
      "<cmd>lua require 'gitsigns'.toggle_current_line_blame<cr>",
      "Toggle Blame"
    },
    ["-"] = {"<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk"},
    ["+"] = {"<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk"}
  },
  ["lcd"] = {"<cmd>lcd %:h<cr>", "Change local dir to path of current file"},
  n = {
    name = "Notes",
    d = {
      "<cmd>ZkNew { dir = vim.env.ZK_NOTEBOOK_DIR .. '/Calendar', title = os.date('%Y%m%d') }<CR>",
      "New diary"
    },
    e = {
      '<cmd>!mv "<cfile>" "<c-r>=expand(\'%:p:h\')<cr>/"<cr>',
      "Embed file moving to current file's folder"
    },
    f = {"<Cmd>ZkNotes { match = {vim.fn.input('Search: ') }}<CR>", "Find"},
    g = {
      "<cmd>lua require('pwnvim.plugins').grammar_check()<cr>", "Check Grammar"
    },
    h = {"<cmd>edit ~/Notes/Notes/HotSheet.md<CR>", "Open HotSheet"},
    i = {
      c = {
        "<cmd>r!/opt/homebrew/bin/icalBuddy --bullet '* ' --timeFormat '\\%H:\\%M' --dateFormat '' --noPropNames --noCalendarNames --excludeAllDayEvents --includeCals 'IC - Work' --includeEventProps datetime,title,attendees,location --propertyOrder datetime,title,attendees,location --propertySeparators '| |\\n    * |\\n    * | |' eventsToday<cr>",
        "Insert today's calendar"
      },
      o = {"<cmd>r!gtm-okr goals<cr>", "Insert OKRs"},
      j = {
        "<cmd>r!( (curl -s https://icanhazdadjoke.com/ | grep '\\\"subtitle\\\"') || curl -s https://icanhazdadjoke.com/ ) | sed 's/<[^>]*>//g' | sed -z 's/\\n/ /'<cr>",
        "Insert joke"
      }
    },
    m = {
      "<cmd>lua require('zk.commands').get('ZkNew')({ dir = vim.fn.input({prompt='Folder: ',default=vim.env.ZK_NOTEBOOK_DIR .. '/Notes/meetings',completion='dir'}), title = vim.fn.input('Title: ') })<CR>",
      "New meeting"
    },
    n = {
      "<Cmd>ZkNew { dir = vim.fn.input({prompt='Folder: ',default=vim.env.ZK_NOTEBOOK_DIR .. '/Notes',completion='dir'}), title = vim.fn.input('Title: ') }<CR>",
      "New"
    },
    o = {"<cmd>ZkNotes<CR>", "Open"},
    t = {"<cmd>ZkTags<CR>", "Open by tag"}
    -- in open note (defined in plugins.lua as local-only shortcuts):
    -- p: new peer note
    -- l: show outbound links
    -- r: show outbound links
    -- i: info preview
  },
  t = {
    name = "Tasks",
    -- d = { "<cmd>lua require('pwnvim.tasks').completeTask()<cr>", "Done" },
    d = {function() require("pwnvim.tasks").completeTaskDirect() end, "Done"},
    c = {function() require("pwnvim.tasks").createTaskDirect() end, "Create"},
    s = {
      function() require("pwnvim.tasks").scheduleTaskPrompt() end, "Schedule"
    },
    t = {
      function() require("pwnvim.tasks").scheduleTaskTodayDirect() end, "Today"
    }
  },
  -- Set cwd to current file's dir
  ["cd"] = {"<cmd>cd %:h<cr>", "Change dir to path of current file"},
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
    d = {":luado return require('pwnvim.tasks').completeTask(line)<cr>", "Done"},
    s = {require("pwnvim.tasks").scheduleTaskBulk, "Schedule"},
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
    f = {":'<,'>ZkMatch<CR>", "Find Selected"}
  },
  i = leader_mappings.i,
  f = leader_mappings.f,
  e = leader_mappings.e,
  q = leader_mappings.q,
  x = leader_mappings.x
}

which_key.register(leader_mappings, {
  mode = "n", -- NORMAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true -- use `nowait` when creating keymaps
})
which_key.register(leader_visual_mappings, {
  mode = "v", -- VISUAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true -- use `nowait` when creating keymaps
})

which_key.register({
  ["<D-j>"] = {"gj", "Down screen line"},
  ["<D-k>"] = {"gk", "Up screen line"},
  ["<D-4>"] = {"g$", "End of screen line"},
  ["<D-6>"] = {"g^", "Beginning of screen line"},
  -- Visually select the text that was last edited/pasted
  -- Similar to gv but works after paste
  ["gV"] = {"`[v`]", "Visually select the text last edited (after paste)"},
  -- Have ctrl-l continue to do what it did, but also temp clear search match highlighting
  Y = {"y$", "Yank to end of line"},
  ["-"] = {"<cmd>NvimTreeFindFile<cr>", "Find current file in file browser"}
}, {mode = "n", noremap = true, silent = true})

-- Make nvim terminal more sane
which_key.register({
  ["<esc>"] = {[[<C-\><C-n>]], "Get to normal mode in terminal"},
  ["M-["] = {"<esc>", "Send escape to terminal"},
  ["<C-v><Esc>"] = {"<esc>", "Send escape to terminal"},
  ["<C-h>"] = {[[<Cmd>wincmd h<CR>]], "Move one window left"},
  ["<C-j>"] = {[[<Cmd>wincmd j<CR>]], "Move one window down"},
  ["<C-k>"] = {[[<Cmd>wincmd k<CR>]], "Move one window up"},
  ["<C-l>"] = {[[<Cmd>wincmd l<CR>]], "Move one window right"},
  ["<C-v><C-h>"] = {[[<C-h>]], "Send c-h to terminal"},
  ["<C-v><C-j>"] = {[[<C-j>]], "Send c-j to terminal"},
  ["<C-v><C-k>"] = {[[<C-k>]], "Send c-k to terminal"},
  ["<C-v><C-l>"] = {[[<C-l>]], "Send c-l to terminal"}
}, {mode = "t", noremap = true, silent = true})

-- Setup tpope unimpaired-like forward/backward shortcuts reminders
which_key.register({
  ["[a"] = "Prev file arg",
  ["]a"] = "Next file arg",
  ["[b"] = {"<Cmd>BufferLineCyclePrev<CR>", "Prev buffer"},
  ["]b"] = {"<Cmd>BufferLineCycleNext<CR>", "Next buffer"},
  ["[c"] = "Prev git hunk",
  ["]c"] = "Next git hunk",
  ["[l"] = "Prev loclist item",
  ["]l"] = "Next loclist item",
  ["[q"] = "Prev quicklist item",
  ["]q"] = "Next quicklist item",
  ["[t"] = {"<Cmd>tabprevious<cr>", "Prev tab"},
  ["[T"] = {"<Cmd>tabprevious<cr>", "First tab"},
  ["]t"] = {"<Cmd>tabnext<cr>", "Next tab"},
  ["]T"] = {"<Cmd>tablast<cr>", "Last tab"},
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
  ["[d"] = {"<cmd>lua vim.diagnostic.goto_prev()<CR>", "Prev diagnostic"},
  ["]d"] = {"<cmd>lua vim.diagnostic.goto_next()<CR>", "Next diagnostic"},
  ["[1"] = {":BufferLineGoToBuffer 1<CR>", "Go to buffer 1"},
  ["]1"] = {":BufferLineGoToBuffer 1<CR>", "Go to buffer 1"},
  ["[2"] = {":BufferLineGoToBuffer 2<CR>", "Go to buffer 2"},
  ["]2"] = {":BufferLineGoToBuffer 2<CR>", "Go to buffer 2"},
  ["[3"] = {":BufferLineGoToBuffer 3<CR>", "Go to buffer 3"},
  ["]3"] = {":BufferLineGoToBuffer 3<CR>", "Go to buffer 3"},
  ["[4"] = {":BufferLineGoToBuffer 4<CR>", "Go to buffer 4"},
  ["]4"] = {":BufferLineGoToBuffer 4<CR>", "Go to buffer 4"},
  ["[5"] = {":BufferLineGoToBuffer 5<CR>", "Go to buffer 5"},
  ["]5"] = {":BufferLineGoToBuffer 5<CR>", "Go to buffer 5"},
  ["[6"] = {":BufferLineGoToBuffer 6<CR>", "Go to buffer 6"},
  ["]6"] = {":BufferLineGoToBuffer 6<CR>", "Go to buffer 6"},
  ["[7"] = {":BufferLineGoToBuffer 7<CR>", "Go to buffer 7"},
  ["]7"] = {":BufferLineGoToBuffer 7<CR>", "Go to buffer 7"},
  ["[8"] = {":BufferLineGoToBuffer 8<CR>", "Go to buffer 8"},
  ["]8"] = {":BufferLineGoToBuffer 8<CR>", "Go to buffer 8"},
  ["[9"] = {":BufferLineGoToBuffer 9<CR>", "Go to buffer 9"},
  ["]9"] = {":BufferLineGoToBuffer 9<CR>", "Go to buffer 9"},
  ["<S-h>"] = {":BufferLineCyclePrev<CR>", "Go to next buffer"},
  ["<S-l>"] = {":BufferLineCycleNext<CR>", "Go to prev buffer"},
  f = "Find next char x",
  F = "Find prev char x",
  t = "Find before prev char x",
  T = "Find before prev char x"
}, {mode = "n", silent = true})

which_key.register({
  f = "Find next char x",
  F = "Find prev char x",
  t = "Find before prev char x",
  T = "Find before prev char x"
}, {mode = "o", silent = true})

-- Flash mappings
-- Note: the regular mappings mess up surround plugin and various modes
-- Flash automatically enhances search (with / or ?) and char search (f, F, t, T)

-- ctrl-s will toggle that enhancement for search when in the midst of searching
which_key.register({
  ["<c-s>"] = {function() require("flash").toggle() end, "Toggle Flash Search"}
}, {mode = "c"})

-- ctrl-s will do general screen jump otherwise
which_key.register({
  ["<c-s>"] = {
    function() require("flash").jump({jump = {autojump = true}}) end,
    "Flash Search"
  }
}, {mode = "n"})

-- Replace vim-visual plugin * and # search of word under cursor
-- The \V tells vim to not treat any special chars as special (except backslash)
-- <cname> won't include a backslash in the word
-- The \< and \> mark word start and end so `*` search for the exact word as a word
-- and `gv` search for the word even if within other words
which_key.register({}, {mode = "n"})

-- Start visual mode and then adjust selection by treesitter nodes with s
-- so `vs` or `vjjs` or whatever should allow selecting a treesitter node
-- or expanding/contracting it with `;` and `,`
which_key.register({
  ["<c-s>"] = {
    function() require("flash").jump() end, "Visual Extend via Flash"
  },
  r = {
    function() require("flash").treesitter() end,
    "Visual Extend to Treesitter block"
  }
}, {mode = "x"})
