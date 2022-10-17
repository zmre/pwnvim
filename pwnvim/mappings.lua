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
      operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
      motions = false, -- adds help for motions
      text_objects = false, -- help for text objects triggered after entering an operator
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
    margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
    padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
    winblend = 0
  },
  layout = {
    height = { min = 4, max = 25 }, -- min and max height of the columns
    width = { min = 20, max = 50 }, -- min and max width of the columns
    spacing = 3, -- spacing between columns
    align = "left" -- align columns left, center or right
  },
  ignore_missing = true, -- enable this to hide mappings for which you didn't specify a label
  hidden = {
    "<silent>", "<CMD>", "<cmd>", "<Cmd>", "<cr>", "<CR>", "call", "lua",
    "^:", "^ "
  }, -- hide mapping boilerplate
  show_help = true, -- show help message on the command line when the popup is visible
  triggers = "auto" -- automatically setup triggers
  -- triggers = {"<leader>"} -- or specify a list manually
})
-- This file is for mappings that will work regardless of filetype. Always available.
local options = { noremap = true, silent = true }

-- Make F1 act like escape for accidental hits
vim.api.nvim_set_keymap('', '#1', '<Esc>', options)
vim.api.nvim_set_keymap('!', '#1', '<Esc>', options)

-- TODO: try using the WinNew and WinClosed autocmd events with CHADtree filetype
-- to remap #2 to either open or close commands. Or BufDelete, BufAdd, BufWinLeave, BufWinEnter
-- Make F2 bring up a file browser
-- vim.api.nvim_set_keymap('', '#2', ':NvimTreeToggle<CR>', options)
-- vim.api.nvim_set_keymap('!', '#2', '<ESC>:NvimTreeToggle<CR>', options)
-- vim.api.nvim_set_keymap('', '-', ':NvimTreeFindFile<CR>', options)
vim.api.nvim_set_keymap('', '#2', '<cmd>NvimTreeToggle<CR>', options)
vim.api.nvim_set_keymap('!', '#2', '<cmd>NvimTreeToggle<CR>', options)
vim.api.nvim_set_keymap('', '-', '<cmd>NvimTreeFindFile<CR>', options)

-- Make ctrl-p open a file finder
-- When using ctrl-p, screen out media files that we probably don't want
-- to open in vim. And if we really want, then we can use ,ff
vim.api
    .nvim_set_keymap('', '<c-p>', ':silent Telescope find_files<CR>', options)
vim.api.nvim_set_keymap('!', '<c-p>', '<ESC>:silent Telescope find_files<CR>',
  options)

-- Make F4 toggle showing invisible characters
vim.api
    .nvim_set_keymap('', '_z', ':set list<CR>:map #4 _Z<CR>', { silent = true })
vim.api.nvim_set_keymap('', '_Z', ':set nolist<CR>:map #4 _z<CR>',
  { silent = true })
vim.api.nvim_set_keymap('', '#4', '_Z', {})

-- Enter the date on F8
vim.api.nvim_set_keymap('', '#8', '"=strftime("%Y-%m-%d")<CR>P', options)
vim.api.nvim_set_keymap('!', '#8', '<C-R>=strftime("%Y-%m-%d")<CR>', options)

-- Make F9 toggle distraction-free writing setup
vim.api.nvim_set_keymap('', '#9', ':TZAtaraxis<CR>', options)
vim.api.nvim_set_keymap('!', '#9', ':TZAtaraxis<CR>', options)

-- Make F12 restart highlighting
vim.api.nvim_set_keymap('', '<F12>', ':syntax sync fromstart<CR>', options)
vim.api
    .nvim_set_keymap('!', '<F12>', '<C-o>:syntax sync fromstart<CR>', options)

-- Have ctrl-l continue to do what it did, but also temp clear search match highlighting
vim.api.nvim_set_keymap('', '<C-l>', ':<C-u>nohlsearch<CR><C-l>',
  { silent = true })
-- Yank to end of line using more familiar method
vim.api.nvim_set_keymap('', 'Y', 'y$', options)

local global_leader_opts = {
  mode = "n", -- NORMAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true -- use `nowait` when creating keymaps
}
local global_leader_opts_visual = {
  mode = "v", -- VISUAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true -- use `nowait` when creating keymaps
}

local leader_mappings = {
  ["e"] = { "<cmd>NvimTreeToggle<cr>", "Explorer" },
  ["b"] = {
    "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<cr>",
    "Buffers"
  },
  ["/"] = { "<cmd>nohlsearch<CR>", "No Highlight" },
  ["x"] = { "<cmd>Bdelete!<CR>", "Close Buffer" },
  ["q"] = {
    [["<cmd>".(get(getqflist({"winid": 1}), "winid") != 0? "cclose" : "botright copen")."<cr>"]],
    "Toggle Quicklist"
  },
  f = {
    name = "Find",
    f = { "<cmd>lua require('telescope.builtin').find_files()<CR>", "Files" },
    g = { "<cmd>lua require('telescope.builtin').live_grep()<CR>", "Grep" },
    b = {
      "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<cr>",
      "Buffers"
    },
    h = { "<cmd>lua require('telescope.builtin').oldfiles()<cr>", "History" },
    q = { "<cmd>lua require('telescope.builtin').quickfix()<cr>", "Quickfix" },
    l = { "<cmd>lua require('telescope.builtin').loclist()<cr>", "Loclist" },
    p = { "<cmd>Telescope projects<cr>", "Projects" },
    k = { "<cmd>Telescope keymaps<cr>", "Keymaps" }
  },
  -- Quickly change indent defaults in a file
  i = {
    name = "Indent",
    ["1"] = { "<cmd>lua require('zmre.options').tabindent()<CR>", "Tab" },
    ["2"] = {
      "<cmd>lua require('zmre.options').twospaceindent()<CR>", "Two Space"
    },
    ["4"] = {
      "<cmd>lua require('zmre.options').fourspaceindent()<CR>",
      "Four Space"
    }
  },
  g = {
    name = "Git",
    s = { "<cmd>lua require('telescope.builtin').git_status()<cr>", "Status" },
    b = {
      "<cmd>lua require('telescope.builtin').git_branches()<cr>",
      "Branches"
    },
    c = {
      "<cmd>lua require('telescope.builtin').git_commits()<cr>", "Commits"
    },
    h = { "<cmd>lua require 'gitsigns'.toggle_current_line_blame", "Toggle Blame" },
    ["-"] = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
    ["+"] = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" }
  },
  n = {
    name = "Notes",
    g = {
      "<cmd>lua require('zmre.plugins').grammar_check()<cr>",
      "Check Grammar"
    },
    n = {
      "<Cmd>ZkNew { dir = vim.fn.input('Folder: ',vim.env.ZK_NOTEBOOK_DIR .. '/Notes','dir'), title = vim.fn.input('Title: ') }<CR>",
      "New"
    },
    o = { "<cmd>ZkNotes<CR>", "Open" },
    t = { "<cmd>ZkTags<CR>", "Open by tag" },
    f = { "<Cmd>ZkNotes { match = vim.fn.input('Search: ') }<CR>", "Find" },
    m = {
      "<cmd>lua require('zk.commands').get('ZkNew')({ dir = vim.fn.input('Folder: ',vim.env.ZK_NOTEBOOK_DIR .. '/Notes/meetings','dir'), title = vim.fn.input('Title: ') })<CR>",
      "New meeting"
    },
    d = {
      "<cmd>ZkNew { dir = vim.env.ZK_NOTEBOOK_DIR .. '/Calendar', title = os.date('%Y-%m-%d') }<CR>",
      "New diary"
    },
    h = { "<cmd>edit ~/Notes/Notes/HotSheet.md<CR>", "Open HotSheet" }
    -- in open note (defined in plugins.lua as local-only shortcuts):
    -- p: new peer note
    -- l: show outbound links
    -- r: show outbound links
    -- i: info preview
  }
}
local leader_visual_mappings = {
  n = { f = { ":'<,'>ZkMatch<CR>", "Find Selected" } }
}

which_key.register(leader_mappings, global_leader_opts)
which_key.register(leader_visual_mappings, global_leader_opts_visual)

vim.api.nvim_set_keymap('', '<leader>fd',
  ':silent Telescope lsp_document_symbols<CR>', options)

-- Set cwd to current file's dir
vim.api.nvim_set_keymap('', '<leader>cd', ':cd %:h<CR>', options)
vim.api.nvim_set_keymap('', '<leader>lcd', ':lcd %:h<CR>', options)
-- Debug syntax files
vim.api.nvim_set_keymap('', '<leader>sd',
  [[:echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')<CR>]],
  options)

-- """"""""" Global Shortcuts """""""""""""

vim.api.nvim_set_keymap('', '<D-j>', 'gj', options)
vim.api.nvim_set_keymap('', '<D-4>', 'g$', options)
vim.api.nvim_set_keymap('', '<D-6>', 'g^', options)
vim.api.nvim_set_keymap('', '<D-0>', 'g^', options)

-- Bubble lines up and down using the unimpaired plugin
vim.api.nvim_set_keymap('n', '<A-Up>', '[e', options)
vim.api.nvim_set_keymap('n', '<A-Down>', ']e', options)
vim.api.nvim_set_keymap('v', '<A-Up>', '[egv', options)
vim.api.nvim_set_keymap('v', '<A-Down>', ']egv', options)

-- Visually select the text that was last edited/pasted
-- Similar to gv but works after paste
vim.api.nvim_set_keymap('', 'gV', '`[v`]', options)

-- What do these do?
-- inoremap <C-U> <C-G>u<C-U>
-- nnoremap & :&&<CR>
-- xnoremap & :&&<CR>

-- Indent/outdent shortcuts
vim.api.nvim_set_keymap('n', '<D-[>', '<<', options)
vim.api.nvim_set_keymap('v', '<D-[>', '<gv', options)
vim.api.nvim_set_keymap('!', '<D-[>', '<C-o><<', options)
vim.api.nvim_set_keymap('n', '<D-]>', '>>', options)
vim.api.nvim_set_keymap('v', '<D-]>', '>gv', options)
vim.api.nvim_set_keymap('!', '<D-]>', '<C-o>>>', options)
-- keep visual block so you can move things repeatedly
vim.api.nvim_set_keymap('v', "<", "<gv", options)
vim.api.nvim_set_keymap('v', ">", ">gv", options)

-- TODO: this should be in programming setup
-- nmap <D-b> :make<CR>
-- imap <D-b> <C-o>:make<CR>

-- easy expansion of the active directory with %% on cmd
vim.api.nvim_set_keymap('c', '%%', "expand('%:h').'/'", options)

-- gx is a built-in to open URLs under the cursor, but when
-- not using netrw, it doesn't work right. Or maybe it's just me
-- but anyway this command works great.
vim.api.nvim_set_keymap('', 'gx',
  ":!open \"<c-r><c-a><cr>\" || xdg-open \"<c-r><c-a><cr>\"",
  options)
vim.api.nvim_set_keymap('', '<CR>',
  ":!open \"<c-r><c-a><cr>\" || xdg-open \"<c-r><c-a><cr>\"",
  options)

-- open/close folds with space bar
vim.api.nvim_set_keymap('', '<Space>',
  [[@=(foldlevel('.')?'za':"\<Space>")<CR>]], options)

-- Make nvim terminal more sane
vim.api.nvim_set_keymap('t', '<Esc>', [[<C-\><C-n>]], options)
vim.api.nvim_set_keymap('t', '<M-[>', "<Esc>", options)
vim.api.nvim_set_keymap('t', '<C-v><Esc>', "<Esc>", options)

-- gui nvim stuff
-- Adjust font sizes
vim.api.nvim_set_keymap('', '<D-=>', [[:silent! let &guifont = substitute(
  \ &guifont,
  \ ':h\zs\d\+',
  \ '\=eval(submatch(0)+1)',
  \ '')<CR>]], options)
vim.api.nvim_set_keymap('', '<D-->', [[:silent! let &guifont = substitute(
  \ &guifont,
  \ ':h\zs\d\+',
  \ '\=eval(submatch(0)-1)',
  \ '')<CR>]], options)

-- Need to map cmd-c and cmd-v to get natural copy/paste behavior
vim.api.nvim_set_keymap('n', '<D-v>', '"*p', options)
vim.api.nvim_set_keymap('v', '<D-v>', '"*p', options)
vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>*', options)
vim.api.nvim_set_keymap('c', '<D-v>', '<C-R>*', options)
vim.api.nvim_set_keymap('v', '<D-c>', '"*y', options)
-- When pasting over selected text, keep original register value
vim.api.nvim_set_keymap('v', 'p', '"_dP', options)

-- cmd-w to close the current buffer
vim.api.nvim_set_keymap('', '<D-w>', ':bd<CR>', options)
vim.api.nvim_set_keymap('!', '<D-w>', '<ESC>:bd<CR>', options)

-- cmd-t or cmd-n to open a new buffer
vim.api.nvim_set_keymap('', '<D-t>', ':enew<CR>', options)
vim.api.nvim_set_keymap('!', '<D-t>', '<ESC>:enew<CR>', options)
vim.api.nvim_set_keymap('', '<D-n>', ':tabnew<CR>', options)
vim.api.nvim_set_keymap('!', '<D-n>', '<ESC>:tabnew<CR>', options)

-- cmd-s to save
vim.api.nvim_set_keymap('', '<D-s>', ':w<CR>', options)
vim.api.nvim_set_keymap('!', '<D-s>', '<ESC>:w<CR>', options)

-- cmd-q to quit
vim.api.nvim_set_keymap('', '<D-q>', ':q<CR>', options)
vim.api.nvim_set_keymap('!', '<D-q>', '<ESC>:q<CR>', options)

-- cmd-o to open
vim.api.nvim_set_keymap('', '<D-o>', ':Telescope file_browser cmd=%:h<CR>',
  options)
vim.api.nvim_set_keymap('!', '<D-o>',
  '<ESC>:Telescope file_browser cmd=%:h<CR>', options)

-- TODO:
-- Use ctrl-x, ctrl-u to complete :emoji: symbols, then use
-- ,e to turn it into a symbol if desired
-- vim.api.nvim_set_keymap('!', '<leader>e',
--                      [[:%s/:\([^:]\+\):/\=emoji#for(submatch(1), submatch(0))/g<CR>]],
--                     options)

-- Setup tpope unimpaired-like forward/backward shortcuts
which_key.register({
  ["[a"] = "Prev file arg",
  ["]a"] = "Next file arg",
  ["[b"] = { '<Cmd>BufferLineCyclePrev<CR>', "Prev buffer" },
  ["]b"] = { '<Cmd>BufferLineCycleNext<CR>', "Next buffer" },
  ["[c"] = "Prev git hunk",
  ["]c"] = "Next git hunk",
  ["[l"] = "Prev loclist item",
  ["]l"] = "Next loclist item",
  ["[q"] = "Prev quicklist item",
  ["]q"] = "Next quicklist item",
  ["[t"] = { '<Cmd>tabprevious', "Prev tab" },
  ["[T"] = { '<Cmd>tabprevious', "First tab" },
  ["]t"] = { '<Cmd>tabnext', "Next tab" },
  ["]T"] = { '<Cmd>tablast', "Last tab" },
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
  ["]d"] = { "<cmd>lua vim.diagnostic.goto_next()<CR>", "Next diagnostic" }
}, { mode = 'n' })

-- Move to previous/next
vim.api.nvim_set_keymap('', '<S-h>', ':BufferLineCyclePrev<CR>', options)
vim.api.nvim_set_keymap('', '<S-l>', ':BufferLineCycleNext<CR>', options)

-- Goto buffer in position...
vim.api.nvim_set_keymap('', '[1', ':BufferLineGoToBuffer 1<CR>', options)
vim.api.nvim_set_keymap('', '[2', ':BufferLineGoToBuffer 2<CR>', options)
vim.api.nvim_set_keymap('', ']2', ':BufferLineGoToBuffer 2<CR>', options)
vim.api.nvim_set_keymap('', '[3', ':BufferLineGoToBuffer 3<CR>', options)
vim.api.nvim_set_keymap('', ']3', ':BufferLineGoToBuffer 3<CR>', options)
vim.api.nvim_set_keymap('', '[4', ':BufferLineGoToBuffer 4<CR>', options)
vim.api.nvim_set_keymap('', ']4', ':BufferLineGoToBuffer 4<CR>', options)
vim.api.nvim_set_keymap('', '[5', ':BufferLineGoToBuffer 5<CR>', options)
vim.api.nvim_set_keymap('', ']5', ':BufferLineGoToBuffer 5<CR>', options)
vim.api.nvim_set_keymap('', '[6', ':BufferLineGoToBuffer 6<CR>', options)
vim.api.nvim_set_keymap('', ']6', ':BufferLineGoToBuffer 6<CR>', options)
vim.api.nvim_set_keymap('', '[7', ':BufferLineGoToBuffer 7<CR>', options)
vim.api.nvim_set_keymap('', ']7', ':BufferLineGoToBuffer 7<CR>', options)
vim.api.nvim_set_keymap('', '[8', ':BufferLineGoToBuffer 8<CR>', options)
vim.api.nvim_set_keymap('', ']8', ':BufferLineGoToBuffer 8<CR>', options)
vim.api.nvim_set_keymap('', '[9', ':BufferLineGoToBuffer 9<CR>', options)
vim.api.nvim_set_keymap('', ']9', ':BufferLineGoToBuffer 9<CR>', options)
-- Close buffer
vim.api.nvim_set_keymap('', '<D-w>', ':Bdelete<CR>', options)
vim.api.nvim_set_keymap('!', '<D-w>', '<ESC>:Bdelete<CR>', options)
vim.api.nvim_set_keymap('', '<A-w>', ':Bdelete<CR>', options)
vim.api.nvim_set_keymap('!', '<A-w>', '<ESC>:Bdelete<CR>', options)
vim.api.nvim_set_keymap('', '<M-w>', ':Bdelete<CR>', options)
vim.api.nvim_set_keymap('!', '<M-w>', '<ESC>:Bdelete<CR>', options)
-- Magic buffer-picking mode
vim.api.nvim_set_keymap('', '<M-b>', ':BufferPick<CR>', options)
vim.api.nvim_set_keymap('!', '<M-b>', '<ESC>:BufferPick<CR>', options)
vim.api.nvim_set_keymap('', '[0', ':BufferPick<CR>', options)
vim.api.nvim_set_keymap('', ']0', ':BufferPick<CR>', options)
vim.api.nvim_set_keymap('', '[\\', ':BufferPick<CR>', options)
vim.api.nvim_set_keymap('', ']\\', ':BufferPick<CR>', options)

-- Pane navigation integrated with tmux
vim.api.nvim_set_keymap('', '<c-h>', ':TmuxNavigateLeft<cr>', { silent = true })
vim.api.nvim_set_keymap('', '<c-j>', ':TmuxNavigateDown<cr>', { silent = true })
vim.api.nvim_set_keymap('', '<c-k>', ':TmuxNavigateUp<cr>', { silent = true })
vim.api.nvim_set_keymap('', '<c-l>', ':TmuxNavigateRight<cr>', { silent = true })
-- add mapping for :TmuxNavigatePrevious ? c-\, the default, used by toggleterm
