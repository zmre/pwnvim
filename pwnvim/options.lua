local M = {}

SimpleUI = (os.getenv("SIMPLEUI") == "1" or os.getenv("TERM_PROGRAM") ==
      "Apple_Terminal" or os.getenv("TERM") == "linux") and
    not vim.g.neovide

M.defaults = function()
  -- disable builtin vim plugins
  vim.g.loaded_gzip = 0
  vim.g.loaded_tar = 0
  vim.g.loaded_tarPlugin = 0
  vim.g.loaded_zipPlugin = 0
  vim.g.loaded_2html_plugin = 0
  vim.g.loaded_netrw = 1       -- disable netrw
  vim.g.loaded_netrwPlugin = 1 -- disable netrw
  -- we just use lua plugins here so disable others
  vim.g.loaded_perl_provider = 0
  vim.g.loaded_node_provider = 0
  vim.g.loaded_python3_provider = 0
  vim.g.loaded_ruby_provider = 0
  -- vim.g.loaded_matchit = 0
  -- vim.g.loaded_matchparen = 0
  vim.g.loaded_spec = 0
  vim.g.vim_markdown_no_default_key_mappings = 1
  vim.g.markdown_folding = 1
  vim.g.vim_markdown_strikethrough = 1
  vim.g.vim_markdown_auto_insert_bullets = 1
  vim.g.vim_markdown_new_list_item_indent = 0
  vim.g.vim_markdown_conceal = 1
  vim.g.vim_markdown_math = 0
  vim.g.vim_markdown_conceal_code_blocks = 0
  vim.g.vim_markdown_frontmatter = 1

  vim.g.db_ui_use_nerd_fonts = true

  -- this would allow spaces in filenames for commands like `gf` but results are really mixed.
  -- commenting for now 2022-12-22
  -- vim.opt.isfname:append { "32" }

  vim.opt.grepprg =
  "rg\\ --vimgrep\\ --no-heading\\ --smart-case\\ --color\\ never"
  vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m,%f"

  -- ignore completions and menus for the below
  vim.opt.wildignore =
  "*/node_modules/*,_site,*/__pycache__/,*/venv/*,*/target/*,*/.vim$,\\~$,*/.log,*/.aux,*/.cls,*/.aux,*/.bbl,*/.blg,*/.fls,*/.fdb*/,*/.toc,*/.out,*/.glo,*/.log,*/.ist,*/.fdb_latexmk,*.bak,*.o,*.a,*.sw?,.git/,*.class,.direnv/,.DS_Store"
  vim.opt.wildmenu = true           -- cmd line completion a-la zsh
  vim.opt.wildmode = "list:longest" -- matches mimic that of bash or zsh

  vim.opt.swapfile = false
  vim.opt.spell = true
  vim.opt.spelllang = "en_us"
  vim.opt.ruler = true      -- show the cursor position all the time
  vim.opt.cursorline = true -- add indicator for current line
  vim.opt.secure = true     -- don't execute shell cmds in .vimrc not owned by me
  vim.opt.history = 50      -- keep 50 lines of command line history
  vim.opt.shell = "zsh"
  vim.opt.modelines = 0     -- Don't allow vim settings embedded in text files for security reasons
  vim.opt.showcmd = true    -- display incomplete commands
  vim.opt.showmode = true   -- display current mode
  -- with backup off and writebackup on: backup current file, deleted afterwards
  vim.opt.backup = false
  vim.opt.writebackup = true
  vim.opt.backupcopy = "auto"
  vim.opt.hidden = true
  vim.opt.cf = true   -- jump to errors based on error files
  vim.o.listchars = "tab:⇥ ,trail:␣,extends:⇉,precedes:⇇,nbsp:·"
  vim.opt.list = true -- render special chars (tabs, trails, ...)
  vim.opt.ttyfast = true
  vim.opt.expandtab = true
  vim.opt.splitbelow = true -- allow splits below
  vim.opt.splitright = true -- and to the right
  vim.opt.dictionary:append { '/usr/share/dict/words', '~/.aspell.english.pws' }
  vim.opt.complete = vim.opt.complete + { 'k', ']' }
  vim.opt.complete = vim.opt.complete - { 'i' }
  vim.opt.encoding = "utf-8"
  vim.opt.backspace = "indent,eol,start" -- allow backspacing over everything in insert mode
  vim.opt.joinspaces = false             -- don't insert two spaces after sentences on joins
  vim.opt.binary = false
  vim.opt.display = "lastline"
  vim.opt.viewoptions = "folds,cursor,unix,slash" -- better unix / windows compatibility
  vim.o.shortmess = "filnxtToSAcOF"
  vim.opt.foldnestmax = 5

  -- wrapping
  vim.opt.wrap = true
  vim.opt.sidescroll = 2    -- min number of columns to scroll from edge
  vim.opt.scrolloff = 8     -- when 4 away from edge start scrolling
  vim.opt.sidescrolloff = 8 -- keep cursor one col from end of line
  vim.opt.textwidth = 0
  vim.opt.breakindent = true
  vim.opt.showbreak = "» "
  vim.opt.breakat:remove { '/', '*', '_', '`' }
  vim.opt.linebreak = true -- wraps on word boundaries but only if nolist is set

  -- Make tabs be spaces of 4 characters by default
  vim.opt.tabstop = 4
  vim.opt.shiftwidth = 4
  vim.opt.softtabstop = 4
  vim.opt.expandtab = true   -- turn tabs to spaces by default

  vim.opt.autoindent = true  -- autoindent to same level as previous line
  vim.opt.smartindent = true -- indent after { and cinwords words
  vim.opt.smartcase = true   -- intelligently ignore case in searches
  vim.opt.ignorecase = true  -- default to not being case sensitive
  vim.opt.smarttab = true
  vim.opt.icm = "nosplit"    -- show substitutions as you type
  vim.opt.hlsearch = true
  vim.opt.updatetime = 250   -- Decrease update time
  vim.wo.signcolumn = 'yes'
  vim.opt.visualbell = true
  vim.opt.autoread = true -- auto reload files changed on disk if not changed in buffer
  vim.opt.cursorline = false
  vim.opt.ttyfast = true
  vim.opt.formatoptions = 'jcroqlt' -- t=text, c=comments, q=format with "gq"
  vim.opt.showmatch = true          -- auto hilights matching bracket or paren
  vim.opt.nrformats = vim.opt.nrformats - { 'octal' }
  vim.opt.shiftround = true
  vim.opt.ttimeout = true
  vim.opt.ttimeoutlen = 50
  vim.opt.fileformats = "unix,dos,mac"
  vim.o.matchpairs = "(:),{:},[:],<:>"
  vim.opt.number = false
  vim.opt.relativenumber = false
  -- noinsert: don't insert until selection made, noselect: don't select automatically
  vim.opt.completeopt = "menu,menuone,noinsert,noselect" -- needed for autocompletion stuff
  vim.opt.conceallevel = 2
  vim.opt.fileencoding = "utf-8"

  -- Globals
  vim.g.vimsyn_embed = 'l' -- Highlight Lua code inside .vim files
  -- vim.g.polyglot_disabled = { 'sensible', 'autoindent' } -- preserve in case I want to bring back polyglot
  vim.g.foldlevelstart = 3

  -- map the leader key
  vim.api.nvim_set_keymap('n', ',', '', {})
  vim.g.mapleader = ',' -- Namespace for custom shortcuts

  if not SimpleUI then
    vim.g.termguicolors = true
    vim.o.termguicolors = true
  else
    vim.g.termguicolors = false
    vim.o.termguicolors = false
  end
  vim.o.background = "dark"

  if not SimpleUI then
    require("onedarkpro").setup({
      -- Call :OnedarkproCache if you make changes below and to speed startups
      caching = true,
      highlights = {
        mkdLink = { fg = "${blue}", style = "underline" },
        bareLink = { fg = "${blue}", style = "underline" },
        mkdURL = { fg = "${green}", style = "underline" },
        mkdInlineURL = { fg = "${blue}", style = "underline" },
        mkdListItem = { fg = "${cyan}" },
        markdownListMarker = { fg = "${cyan}" },
        mkdListItemCheckbox = { fg = "${green}" },
        -- markdownCheckbox                           = { fg = "${purple}" },
        -- markdownCheckboxUnchecked                  = { fg = "${purple}" },
        -- markdownCheckboxChecked                    = { fg = "${green}" },
        markdownCheckboxCanceled = {
          fg = "${comment}",
          style = "strikethrough"
        },
        markdownCheckboxPostponed = { fg = "${comment}" },
        markdownStrikethrough = {
          fg = "${comment}",
          style = "strikethrough"
        },
        markdownTag = { fg = "${comment}" },
        doneTag = { fg = "${comment}", style = "italic" },
        highPrioTask = { fg = "${red}", style = "bold" },
        -- mkdLinkTitle
        -- mkdID
        -- mkdDelimiter
        -- mkdInlineURL
        -- mkdCode
        -- mkdFootnote
        -- mkdMath
        -- htmlLink
        TSURI = { fg = "${blue}", style = "underline" },
        TSPunctSpecial = { fg = "${red}" },
        markdownTSTitle = { fg = "${cyan}", style = "bold" },
        markdownAutomaticLink = { fg = "${blue}", style = "underline" },
        markdownLink = { fg = "${green}", style = "underline" },
        markdownLinkText = { fg = "${blue}", style = "underline" },
        markdownUrl = { fg = "${green}", style = "underline" },
        markdownWikiLink = { fg = "${blue}", style = "underline" },
        ["@text.title.1"] = { fg = "${yellow}", style = "bold" },
        markdownH1 = { fg = "${yellow}", style = "bold" },
        ["@text.title.2"] = { fg = "${yellow}", style = "bold" },
        markdownH2 = { fg = "${yellow}", style = "bold" },
        ["@text.title.3"] = { fg = "${yellow}" },
        markdownH3 = { fg = "${yellow}" },
        ["@text.title.4"] = { fg = "${green}", style = "italic" },
        markdownH4 = { fg = "${green}", style = "italic" },
        ["@text.title.5"] = { fg = "${green}", style = "italic" },
        markdownH5 = { fg = "${green}", style = "italic" },
        ["@text.title.6"] = { fg = "${green}", style = "italic" },
        markdownH6 = { fg = "${green}", style = "italic" },
        htmlH1 = { fg = "${yellow}", style = "bold" },
        htmlH2 = { fg = "${yellow}", style = "bold" },
        htmlH3 = { fg = "${yellow}" },
        htmlH4 = { fg = "${green}", style = "italic" },
        htmlH5 = { fg = "${green}", style = "italic" },
        htmlH6 = { fg = "${green}", style = "italic" },
        markdownBold = { fg = "#ffffff", style = "bold" },
        htmlBold = { fg = "#ffffff", style = "bold" },
        markdownItalic = { fg = "#eeeeee", style = "italic" },
        htmlItalic = { fg = "#eeeeee", style = "italic" },
        markdownBoldItalic = { fg = "#ffffff", style = "bold,italic" },
        htmlBoldItalic = { fg = "#ffffff", style = "bold,italic" },
        SpellBad = { style = "undercurl", sp = "${red}" },
        SpellCap = { style = "undercurl", sp = "${cyan}" },
        SpellRare = { style = "undercurl", sp = "Magenta" },
        SpellLocal = { style = "undercurl", sp = "${cyan}" },
        IndentBlanklineChar = { fg = "#444444" },
        -- Todo                                       = { fg = "#282c34", bg = "${highlight}", style = "bold" },
        VertSplit = { fg = "#202020", bg = "#606060" },
        Folded = { fg = "#c0c8d0", bg = "#384058" },
        ["@comment.markdown"] = { fg = "${comment}" },
        ["@field.markdown_inline"] = { fg = "${purple}" },
        ["@text.literal.markdown_inline"] = { fg = "${green}" },
        ["@text.reference.markdown_inline"] = {
          fg = "${blue}",
          style = "underline"
        },
        ["@text.underline"] = { style = "underline" },
        ["@text.strong.markdown_inline"] = {
          fg = "#ffffff",
          style = "bold"
        },
        ["@text.emphasis.markdown_inline"] = {
          fg = "#eeeeee",
          style = "italic"
        },
        ["@strikethrough.markdown_inline"] = {
          fg = "${comment}",
          style = "strikethrough"
        },
        ["@tag"] = { fg = "${comment}" },
        ["@block_quote.markdown"] = { fg = "${purple}", style = "italic" },
        ["@text.title.markdown"] = { fg = "${yellow}", style = "bold" },
        -- ["@parameter.markdown_inline"] = { fg = theme.palette.fg },
        ["@punctuation.special.markdown"] = { fg = "${cyan}" },
        ["@punctuation.delimiter.markdown_inline"] = { fg = "${orange}" },
        ["@text.uri.markdown_inline"] = { fg = "${blue}" },
        ["@text.todo.unchecked"] = {
          fg = "#ffffff",
          bg = "",
          style = "bold"
        },
        ["@text.todo.checked"] = { fg = "${green}", style = "bold" },

        TelescopeBorder = {
          fg = "${telescope_results}",
          bg = "${telescope_results}"
        },
        TelescopePromptBorder = {
          fg = "${telescope_prompt}",
          bg = "${telescope_prompt}"
        },
        TelescopePromptCounter = { fg = "${fg}" },
        TelescopePromptNormal = {
          fg = "${fg}",
          bg = "${telescope_prompt}"
        },
        TelescopePromptPrefix = {
          fg = "${purple}",
          bg = "${telescope_prompt}"
        },
        TelescopePromptTitle = {
          fg = "${telescope_prompt}",
          bg = "${purple}"
        },

        TelescopePreviewTitle = {
          fg = "${telescope_results}",
          bg = "${green}"
        },
        TelescopeResultsTitle = {
          fg = "${telescope_results}",
          bg = "${telescope_results}"
        },

        TelescopeMatching = { fg = "${blue}" },
        TelescopeNormal = { bg = "${telescope_results}" },
        TelescopeSelection = { bg = "${telescope_prompt}" }
      },
      styles = {                -- Choose from "bold,italic,underline"
        virtual_text = "italic" -- Style that is applied to virtual text
      },
      plugins = { all = true },
      options = {
        bold = not SimpleUI,
        italic = not SimpleUI,
        underline = not SimpleUI,
        undercurl = not SimpleUI,
        cursorline = true,
        transparency = false,
        terminal_colors = false,
        highlight_inactive_windows = true
      },
      colors = {
        onedark = {
          telescope_prompt = "#2e323a",
          telescope_results = "#21252d"
        },
        onelight = {
          telescope_prompt = "#f5f5f5",
          telescope_results = "#eeeeee"
        }
      }
    })
  end

  local cscheme
  if SimpleUI then
    cscheme = "ir_black"
  else
    cscheme = "onedark"
  end
  vim.cmd("colorscheme " .. cscheme)
  vim.api.nvim_exec([[
    filetype plugin indent on
    syntax on
    syntax sync minlines=5000
  ]], false)

  -- Brief highlight on yank
  vim.api.nvim_exec([[
    augroup YankHighlight
        autocmd!
        autocmd TextYankPost * silent! lua vim.highlight.on_yank()
    augroup end
    ]], false)
end

M.gui = function()
  vim.opt.title = true
  vim.opt.switchbuf = "useopen,usetab,newtab"
  -- vim.opt.guifont = "Liga DejaVuSansMono Nerd Font:h16"
  -- vim.opt.guifont = "FiraCode Nerd Font:h16" -- no italics
  -- if vim.loop.os_uname().sysname == "Darwin" then
  if vim.fn.has('mac') == 1 then
    vim.opt.guifont = "Hasklug Nerd Font:h18"
  else
    vim.opt.guifont = "Hasklug Nerd Font:h9"
  end

  vim.g.neovide_transparency = 0.92
  vim.g.neovide_cursor_animation_length = 0.01
  vim.g.neovide_cursor_trail_length = 0.1
  vim.g.neovide_cursor_antialiasing = true
  vim.g.neovide_refresh_rate = 60
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_input_macos_alt_is_meta = false
  vim.g.neovide_hide_mouse_when_typing = false

  vim.opt.mouse = "nv" -- only use mouse in normal and visual modes (notably not insert and command)
  vim.opt.mousemodel = "popup_setpos"
  -- use the system clipboard for all unnamed yank operations
  vim.opt.clipboard = "unnamedplus"
  vim.cmd([[set guioptions="gmrLae"]])

  -- nvim-qt options
  -- Disable GUI Tabline
  vim.api.nvim_exec([[
      if exists(':GuiTabline')
          GuiTabline 0
      endif
    ]], false)
end

M.twospaceindent = function()
  vim.bo.textwidth = 0
  vim.bo.tabstop = 2
  vim.bo.shiftwidth = 2
  vim.bo.softtabstop = 2
  vim.bo.expandtab = true -- turn tabs to spaces by default
  vim.bo.autoindent = true
  -- vim.cmd('retab')
end

M.fourspaceindent = function()
  vim.bo.textwidth = 0
  vim.bo.tabstop = 4
  vim.bo.shiftwidth = 4
  vim.bo.softtabstop = 4
  vim.bo.expandtab = true -- turn tabs to spaces by default
  vim.bo.autoindent = true
  -- vim.cmd('retab')
end

M.tabindent = function()
  vim.bo.textwidth = 0
  vim.bo.tabstop = 4
  vim.bo.shiftwidth = 4
  vim.bo.softtabstop = 4
  vim.bo.expandtab = false -- don't turn tabs to spaces
  vim.bo.autoindent = true
end

M.retab = function() vim.cmd('%retab!') end

M.programming = function()
  vim.opt.number = true
  vim.wo.number = true
  vim.wo.spell = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = true -- add indicator for current line

  M.twospaceindent()

  -- Could be a performance penalty on this
  -- Will make periodic checks to see if the file changed
  vim.api.nvim_exec([[
    augroup programming
      autocmd!
      autocmd CursorHold,CursorHoldI * silent! checktime
    augroup END
  ]], false)

  -- Load direnv when we're in a programming file as we may want
  -- the nix environment provided. Run explicitly since the autocmds
  -- might not otherwise fire.
  vim.cmd('packadd direnv.vim')
  vim.cmd('DirenvExport')
end

return M
