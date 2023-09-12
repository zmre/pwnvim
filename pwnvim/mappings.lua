-- We use which-key in mappings, which is loaded before plugins, so set up here
local which_key = require("which-key")
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
      motions = true, -- adds help for motions
      text_objects = true, -- help for text objects triggered after entering an operator
      windows = true, -- default bindings on <c-w>
      nav = true, -- misc bindings to work with windows
      z = true, -- bindings for folds, spelling and others prefixed with z
      g = true -- bindings for prefixed with g
    }
  },
  icons = {
    breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
    separator = "➜", -- symbol used between a key and it's label
    group = "+" -- symbol prepended to a group
  },
  popup_mappings = {
    scroll_down = "<c-d>", -- binding to scroll down inside the popup
    scroll_up = "<c-u>" -- binding to scroll up inside the popup
  },
  window = {
    border = "rounded", -- none, single, double, shadow
    position = "bottom", -- bottom, top
    margin = {1, 0, 1, 0}, -- extra window margin [top, right, bottom, left]
    padding = {2, 2, 2, 2}, -- extra window padding [top, right, bottom, left]
    winblend = 0
  },
  layout = {
    height = {min = 4, max = 25}, -- min and max height of the columns
    width = {min = 20, max = 50}, -- min and max width of the columns
    spacing = 3, -- spacing between columns
    align = "left" -- align columns left, center or right
  },
  ignore_missing = true, -- enable this to hide mappings for which you didn't specify a label
  hidden = {
    "<silent>", "<CMD>", "<cmd>", "<Cmd>", "<cr>", "<CR>", "call", "lua", "^:",
    "^ "
  }, -- hide mapping boilerplate
  show_help = true, -- show help message on the command line when the popup is visible
  triggers = "auto" -- automatically setup triggers
  -- triggers = {"<leader>"}
  -- triggers_nowait = {"'", '"', "y", "d"}
})
-- This file is for mappings that will work regardless of filetype. Always available.
local options = {noremap = true, silent = true}

for _, m in ipairs({"", "i", "c"}) do
  which_key.register({
    -- Make F1 act like escape for accidental hits
    ["#1"] = {"<Esc>", "Escape"},
    -- Make F2 bring up a file browser
    ["#2"] = {"<cmd>NvimTreeToggle<cr>", "Toggle file browser"},
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
    ["<D-g>"] = {'"*p', "paste"}
  }, {mode = m, noremap = true, silent = true})
end

-- Make F4 toggle showing invisible characters
vim.api
    .nvim_set_keymap("", "_z", ":set list<CR>:map #4 _Z<CR>", {silent = true})
vim.api.nvim_set_keymap("", "_Z", ":set nolist<CR>:map #4 _z<CR>",
                        {silent = true})
vim.api.nvim_set_keymap("", "#4", "_Z", {})

-- Enter the date on F8
vim.api.nvim_set_keymap("", "#8", '"=strftime("%Y-%m-%d")<CR>P', options)
vim.api.nvim_set_keymap("!", "#8", '<C-R>=strftime("%Y-%m-%d")<CR>', options)

-- Center screen vertically when navigating by half screens
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Center search hits vertically on screen
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Move visually selected lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

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
}, {mode = "", noremap = true, silent = true})

-- Bubble lines up and down using the unimpaired plugin
vim.api.nvim_set_keymap("n", "<A-Up>", "[e", options)
vim.api.nvim_set_keymap("n", "<A-Down>", "]e", options)
vim.api.nvim_set_keymap("v", "<A-Up>", "[egv", options)
vim.api.nvim_set_keymap("v", "<A-Down>", "]egv", options)

-- Indent/outdent shortcuts
vim.api.nvim_set_keymap("n", "<D-[>", "<<", options)
vim.api.nvim_set_keymap("v", "<D-[>", "<gv", options)
vim.api.nvim_set_keymap("!", "<D-[>", "<C-o><<", options)
vim.api.nvim_set_keymap("n", "<D-]>", ">>", options)
vim.api.nvim_set_keymap("v", "<D-]>", ">gv", options)
vim.api.nvim_set_keymap("!", "<D-]>", "<C-o>>>", options)
-- keep visual block so you can move things repeatedly
vim.api.nvim_set_keymap("v", "<", "<gv", options)
vim.api.nvim_set_keymap("v", ">", ">gv", options)

-- easy expansion of the active directory with %% on cmd
local options_nosilent = {noremap = true, silent = false}

vim.api.nvim_set_keymap("c", "%%", "<c-r>=expand('%:p:h')<cr>/",
                        options_nosilent)

-- gx is a built-in to open URLs under the cursor, but when
-- not using netrw, it doesn't work right. Or maybe it's just me
-- but anyway this command works great.
-- /Users/pwalsh/Documents/md2rtf-style.html
-- ../README.md
-- ~/Desktop/Screen Shot 2018-04-06 at 5.19.32 PM.png
-- [abc](https://github.com/adsr/mle/commit/e4dc4314b02a324701d9ae9873461d34cce041e5.patch)
vim.api.nvim_set_keymap("", "gx",
                        ':silent !open "<c-r><c-f>" || xdg-open "<c-r><c-f>"<cr>',
                        options)
vim.api.nvim_set_keymap("v", "gx",
                        '"0y:silent !open "<c-r>0" || xdg-open "<c-r>0"<cr>gv',
                        options)

-- open/close folds with space bar
vim.api.nvim_set_keymap("", "<Space>",
                        [[@=(foldlevel('.')?'za':"\<Space>")<CR>]], options)

which_key.register({
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
  }
}, {mode = ""})

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

-- gui nvim stuff
-- Adjust font sizes
vim.api.nvim_set_keymap("", "<D-=>", [[:silent! let &guifont = substitute(
  \ &guifont,
  \ ':h\zs\d\+',
  \ '\=eval(submatch(0)+1)',
  \ '')<CR>]], options)
vim.api.nvim_set_keymap("", "<C-=>", [[:silent! let &guifont = substitute(
  \ &guifont,
  \ ':h\zs\d\+',
  \ '\=eval(submatch(0)+1)',
  \ '')<CR>]], options)
vim.api.nvim_set_keymap("", "<D-->", [[:silent! let &guifont = substitute(
  \ &guifont,
  \ ':h\zs\d\+',
  \ '\=eval(submatch(0)-1)',
  \ '')<CR>]], options)
vim.api.nvim_set_keymap("", "<C-->", [[:silent! let &guifont = substitute(
  \ &guifont,
  \ ':h\zs\d\+',
  \ '\=eval(submatch(0)-1)',
  \ '')<CR>]], options)

-- Need to map cmd-c and cmd-v to get natural copy/paste behavior
vim.api.nvim_set_keymap("n", "<D-v>", '"*p', options)
vim.api.nvim_set_keymap("v", "<D-v>", '"*p', options)
vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>*", options)
vim.api.nvim_set_keymap("c", "<D-v>", "<C-R>*", options)
vim.api.nvim_set_keymap("v", "<D-c>", '"*y', options)
-- When pasting over selected text, keep original register value
vim.api.nvim_set_keymap("v", "p", '"_dP', options)

-- cmd-w to close the current buffer
vim.api.nvim_set_keymap("", "<D-w>", ":bd<CR>", options)
vim.api.nvim_set_keymap("!", "<D-w>", "<ESC>:bd<CR>", options)

-- cmd-t or cmd-n to open a new buffer
vim.api.nvim_set_keymap("", "<D-t>", ":enew<CR>", options)
vim.api.nvim_set_keymap("!", "<D-t>", "<ESC>:enew<CR>", options)
vim.api.nvim_set_keymap("", "<D-n>", ":tabnew<CR>", options)
vim.api.nvim_set_keymap("!", "<D-n>", "<ESC>:tabnew<CR>", options)

-- cmd-s to save
vim.api.nvim_set_keymap("", "<D-s>", ":w<CR>", options)
vim.api.nvim_set_keymap("!", "<D-s>", "<ESC>:w<CR>", options)

-- cmd-q to quit
vim.api.nvim_set_keymap("", "<D-q>", ":q<CR>", options)
vim.api.nvim_set_keymap("!", "<D-q>", "<ESC>:q<CR>", options)

-- cmd-o to open
-- vim.api.nvim_set_keymap("", "<D-o>", ":Telescope file_browser cmd=%:h<CR>", options)
-- vim.api.nvim_set_keymap("!", "<D-o>", "<ESC>:Telescope file_browser cmd=%:h<CR>", options)

-- emacs bindings to jump around in lines
vim.api.nvim_set_keymap("i", "<C-e>", "<C-o>A", options)
vim.api.nvim_set_keymap("i", "<C-a>", "<C-o>I", options)

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
  ["<S-l>"] = {":BufferLineCycleNext<CR>", "Go to prev buffer"}
}, {mode = "n", silent = true})

-- Close buffer
vim.api.nvim_set_keymap("", "<D-w>", ":Bdelete<CR>", options)
vim.api.nvim_set_keymap("!", "<D-w>", "<ESC>:Bdelete<CR>", options)
vim.api.nvim_set_keymap("", "<A-w>", ":Bdelete<CR>", options)
vim.api.nvim_set_keymap("!", "<A-w>", "<ESC>:Bdelete<CR>", options)
vim.api.nvim_set_keymap("", "<M-w>", ":Bdelete<CR>", options)
vim.api.nvim_set_keymap("!", "<M-w>", "<ESC>:Bdelete<CR>", options)
-- Magic buffer-picking mode
vim.api.nvim_set_keymap("", "<M-b>", ":BufferLinePick<CR>", options)
vim.api.nvim_set_keymap("!", "<M-b>", "<ESC>:BufferLinePick<CR>", options)
vim.api.nvim_set_keymap("", "[0", ":BufferLinePick<CR>", options)
vim.api.nvim_set_keymap("", "]0", ":BufferLinePick<CR>", options)

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
which_key.register({
  ["*"] = {
    function()
      local text = "\\<" .. string.gsub(vim.fn.expand("<cword>"), "/", "\\/") ..
                       "\\>"
      -- vim.cmd("/" .. text) -- works, but doesn't trigger flash
      vim.api.nvim_feedkeys("/\\V" .. text, 'n', false)
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
      vim.api.nvim_feedkeys("?\\V" .. text, 'n', false)
    end, "Find word under cursor backward"
  },
  g = {
    ["*"] = {
      function()
        -- Same as above, but don't qualify as full word only
        local text = string.gsub(vim.fn.expand("<cword>"), "/", "\\/")
        vim.api.nvim_feedkeys("/\\V" .. text, 'n', false)
      end, "Find partial word under cursor forward"
    },
    ["#"] = {
      function()
        -- Same as above, but don't qualify as full word only
        local text = string.gsub(vim.fn.expand("<cword>"), "?", "\\?")
        vim.api.nvim_feedkeys("?" .. text, 'n', false)
      end, "Find partial word under cursor backward"
    }
  }
}, {mode = "n"})
-- Send cursor somewhere on screen and pick a text object from it.
-- Uses operator pending mode so you start it with something like `yr` then
-- after jump pick the text object like `iw` and you'll copy that other thing
-- and be back where you were at the start.
which_key.register({
  r = {function() require("flash").remote() end, "Remote Flash"},
  S = {function() require("flash").treesitter() end, "Flash Treesitter"}
}, {mode = "o"})

-- Start visual mode and then adjust selection by treesitter nodes with s
-- so `vs` or `vjjs` or whatever should allow selecting a treesitter node
-- or expanding/contracting it with `;` and `,`
which_key.register({
  r = {function() require("flash").jump() end, "Visual Flash Jump"},
  s = {function() require("flash").treesitter() end, "Visual Flash Treesitter"}
}, {mode = "x"})
