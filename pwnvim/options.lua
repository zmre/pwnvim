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
  -- vim.g.loaded_python3_provider = 0 -- moved to flake for different modes
  vim.g.loaded_ruby_provider = 0
  -- vim.g.loaded_matchit = 0
  -- vim.g.loaded_matchparen = 1 -- to disable built in paren matching
  vim.g.loaded_spec = 0
  vim.g.vim_markdown_no_default_key_mappings = 1
  -- vim.g.markdown_folding = 1
  vim.g.vim_markdown_strikethrough = 1
  vim.g.vim_markdown_auto_insert_bullets = 1
  vim.g.vim_markdown_new_list_item_indent = 0
  vim.g.vim_markdown_conceal = 1
  vim.g.vim_markdown_math = 0
  vim.g.vim_markdown_conceal_code_blocks = 0
  vim.g.vim_markdown_frontmatter = 1


  -- my shada is so large it takes up half of startup time to process; constraining what it keeps here
  -- previous value: !,'100,<50,s10,h'
  vim.opt.shada = { "'50", "<0", ":5", "/0", '"0', "@5", "f10", "h", "s10" }
  -- The "'#" option remembers some number of marks, but actually controls how many files in the oldfiles list
  -- this would allow spaces in filenames for commands like `gf` but results are really mixed.
  -- commenting for now 2022-12-22
  -- vim.opt.isfname:append { "32" }

  vim.opt.foldenable = false

  vim.opt.grepprg = "rg --vimgrep --no-heading --hidden --smart-case --color never"
  vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m,%f"

  -- ignore completions and menus for the below
  vim.opt.wildignore =
  "*/node_modules/*,_site,*/__pycache__/,*/venv/*,*/target/*,*/.vim$,\\~$,*/.log,*/.aux,*/.cls,*/.aux,*/.bbl,*/.blg,*/.fls,*/.fdb*/,*/.toc,*/.out,*/.glo,*/.log,*/.ist,*/.fdb_latexmk,*.bak,*.o,*.a,*.sw?,.git/,*.class,.direnv/,.DS_Store,*/Backups/*"
  vim.opt.wildmenu = true           -- cmd line completion a-la zsh
  vim.opt.wildmode = "list:longest" -- matches mimic that of bash or zsh

  vim.opt.cmdheight = 1
  vim.opt.cmdwinheight = 5

  vim.opt.swapfile = true -- I've lived without them for years, but recent crashes have me reconsidering
  -- The swap files will be wiped on reboot (cuz /tmp), which could mean lost work on system crash; nvim will create
  -- the dir if it doesn't exist. The double slash ending means filenames will include full path to original file.
  vim.opt.directory = "/tmp/nvim-swap//"
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
  vim.opt.cf = true -- jump to errors based on error files
  vim.o.listchars =
  "tab:⇥ ,trail:␣,multispace:␣,extends:⇉,precedes:⇇,nbsp:·" --,eol:↴" -- ,space:⋅"
  vim.opt.list = false -- render special chars (tabs, trails, ...)
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
  vim.opt.timeout = true
  vim.opt.timeoutlen = 300
  vim.opt.ttimeout = true
  vim.opt.ttimeoutlen = 50
  vim.opt.fileformats = "unix,dos,mac"
  vim.o.matchpairs = "(:),{:},[:],<:>"
  vim.opt.number = false
  vim.opt.relativenumber = false
  -- noinsert: don't insert until selection made, noselect: don't select automatically
  vim.opt.completeopt = "menu,menuone,noinsert,noselect" -- needed for autocompletion stuff
  vim.opt.conceallevel = 2
  if vim.api.nvim_buf_get_option(0, 'modifiable') then
    vim.opt.fileencoding = "utf-8"
  end

  -- Globals
  vim.g.vimsyn_embed = 'l'                                           -- Highlight Lua code inside .vim files
  vim.g.polyglot_disabled = { 'sensible', 'autoindent', 'ftdetect' } -- preserve in case I want to bring back polyglot
  vim.opt.foldlevelstart = 10

  -- map the leader key to ,
  -- note: comma would typically go backwards in a f or t character search (where ; goes ahead)
  vim.api.nvim_set_keymap('n', ',', '', {}) -- first unset it though
  vim.api.nvim_set_keymap('v', ',', '', {}) -- first unset it though
  vim.g.mapleader = ','                     -- Namespace for custom shortcuts

  vim.api.nvim_exec2([[
    filetype plugin indent on
    syntax off
    syntax sync minlines=2000
  ]], { output = false })

  -- Brief highlight on yank
  vim.api.nvim_exec2([[
    augroup YankHighlight
        autocmd!
        autocmd TextYankPost * silent! lua vim.hl.on_yank()
    augroup end
    ]], { output = false })
end

M.colors_cat = function()
  vim.g.termguicolors = not SimpleUI
  vim.o.termguicolors = not SimpleUI
  vim.o.background = "dark"

  require("catppuccin").setup({
    flavour = "macchiato", -- latte, frappe, macchiato, mocha
    background = {         -- :h background
      light = "latte",
      dark = "macchiato",
    },
    transparent_background = true, -- disables setting the background color.
    dim_inactive = {
      enabled = true,              -- dims the background color of inactive window
      shade = "dark",
      percentage = 0.15,           -- percentage of the shade to apply to the inactive window
    },
    integrations = {
      alpha = false,
      cmp = true,
      copilot_vim = true,
      dropbar = {
        enabled = true,
        color_mode = true,
      },
      dashboard = false,
      flash = true,
      gitsigns = true,
      gitgutter = false,
      illuminate = false,
      mini = { enabled = false },
      neogit = false,
      nvimtree = false,
      treesitter = true,
      notify = true,
      nvim_surround = true,
      markdown = true,
      render_markdown = true,
      noice = true,
      ufo = true,
      semantic_tokens = true,
      treesitter_context = true,
      lsp_trouble = true,
      telescope = { enabled = true },
      which_key = true,
      -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
    },
    custom_highlights = function(colors)
      return {
        mkdLink = { fg = colors.blue, style = { "underline" } },
        bareLink = { fg = colors.blue, style = { "underline" } },
        mkdURL = { fg = colors.green, style = { "underline" } },
        ["@markup.link.label"] = { link = "mkdLink" },
        ["@markup.link.url"] = { link = "mkdURL" },
        mkdInlineURL = { fg = colors.blue, style = { "underline" } },
        mkdListItem = { fg = colors.teal },
        markdownListMarker = { fg = colors.teal },
        mkdListItemCheckbox = { fg = colors.green },
        markdownCheckboxCanceled = { fg = colors.surface2, style = { "strikethrough" } },
        markdownCheckboxPostponed = { fg = colors.surface2 },
        markdownStrikethrough = { fg = colors.surface2, style = { "strikethrough" } },
        markdownTag = { fg = colors.surface2 },
        doneTag = { fg = colors.surface2, style = { "italic" } },
        highPrioTask = { fg = colors.red, style = { "bold" } },
        TSURI = { fg = colors.blue, style = { "underline" } },
        TSPunctSpecial = { fg = colors.red },
        markdownTSTitle = { fg = colors.teal, style = { "bold" } },
        markdownAutomaticLink = { fg = colors.blue, style = { "underline" } },
        markdownLink = { fg = colors.green, style = { "underline" } },
        markdownLinkText = { fg = colors.blue, style = { "underline" } },
        ["@link_text"] = { fg = colors.blue, style = { "underline", "bold" } },
        markdownUrl = { fg = colors.green, style = { "underline" } },
        markdownWikiLink = { fg = colors.blue, style = { "underline" } },
        ["@markup.heading.1"] = { fg = colors.yellow, style = { "bold" } },
        markdownH1 = { fg = colors.yellow, style = { "bold" } },
        ["@markup.heading.2"] = { fg = colors.yellow, style = { "bold" } },
        markdownH2 = { fg = colors.yellow, style = { "bold" } },
        ["@markup.heading.3"] = { fg = colors.yellow },
        markdownH3 = { fg = colors.yellow },
        ["@markup.heading.4"] = { fg = colors.green, style = { "italic" } },
        markdownH4 = { fg = colors.green, style = { "italic" } },
        ["@markup.heading.5"] = { fg = colors.green, style = { "italic" } },
        markdownH5 = { fg = colors.green, style = { "italic" } },
        ["@markup.heading.6"] = { fg = colors.green, style = { "italic" } },
        markdownH6 = { fg = colors.green, style = { "italic" } },
        htmlH1 = { fg = colors.yellow, style = { "bold" } },
        htmlH2 = { fg = colors.yellow, style = { "bold" } },
        htmlH3 = { fg = colors.yellow },
        htmlH4 = { fg = colors.green, style = { "italic" } },
        htmlH5 = { fg = colors.green, style = { "italic" } },
        htmlH6 = { fg = colors.green, style = { "italic" } },
        markdownBold = { fg = "#ffffff", style = { "bold" } },
        htmlBold = { fg = "#ffffff", style = { "bold" } },
        markdownItalic = { fg = "#eeeeee", style = { "italic" } },
        htmlItalic = { fg = "#eeeeee", style = { "italic" } },
        markdownBoldItalic = { fg = "#ffffff", style = { "bold", "italic" } },
        htmlBoldItalic = { fg = "#ffffff", style = { "bold", "italic" } },
        SpellBad = { style = { "undercurl" }, sp = colors.red },
        SpellCap = { style = { "undercurl" }, sp = colors.teal },
        SpellRare = { style = { "undercurl" }, sp = colors.lavender },
        SpellLocal = { style = { "undercurl" }, sp = colors.teal },
        MatchParen = { bg = "#555555", style = { "italic" } },
        IndentBlanklineChar = { fg = "#444444" },
        -- Todo                                       = { fg = "#282c34", bg = "${highlight}", bold = true },
        VertSplit = { fg = "#202020", bg = "#606060" },
        Folded = { fg = "#c0c8d0", bg = "#384058" },
        ["@comment.markdown"] = { fg = colors.surface2 },
        ["@field.markdown_inline"] = { fg = colors.lavender },
        ["@markup.raw"] = { fg = colors.green },
        ["@markup.underline"] = { style = { "underline" } },
        ["@markup.strong.markdown_inline"] = { fg = "#ffffff", style = { "bold" } },
        ["@markup.emphasis.markdown_inline"] = { fg = "#eeeeee", style = { "italic" } },
        ["@markup.strikethrough.markdown_inline"] = {
          fg = colors.surface2,
          style = { "strikethrough" }
        },
        ["@tag"] = { fg = colors.surface2 },
        ["@block_quote.markdown"] = { fg = colors.lavender, style = { "italic" } },
        ["@punctuation.special.markdown"] = { fg = colors.teal },
        ["@punctuation.delimiter.markdown_inline"] = { fg = colors.peach },
        ["@markup.link.url.markdown_inline"] = { fg = colors.blue },
        ["@markup.list.unchecked"] = { fg = "#ffffff", bg = "", style = { "bold" } },
        ["@markup.list.checked"] = { fg = colors.green, style = { "bold" } },

        -- Trouble windows
        TroubleNormalNC = { bg = "#221133" },
        TroubleNormal = { bg = "#222244" },
      }
    end

  })
  local cscheme
  if SimpleUI then
    cscheme = "ir_black"
  else
    cscheme = "catppuccin"
  end
  vim.cmd.colorscheme(cscheme)
end

M.colors_onedark = function()
  vim.g.termguicolors = not SimpleUI
  vim.o.termguicolors = not SimpleUI
  vim.o.background = "dark"

  if not SimpleUI then
    require("onedarkpro").setup({
      -- Call :OnedarkproCache if you make changes below and to speed startups
      caching = true,
      highlights = {
        mkdLink = { fg = "${blue}", underline = true },
        bareLink = { link = "mkdLink" },
        mkdInlineURL = { link = "mkdLink" },
        TSURI = { link = "mkdLink" },
        mkdURL = { fg = "${green}", underline = true },
        markdownAutomaticLink = { link = "mkdLink" },
        markdownLink = { link = "mkdURL" },
        markdownLinkText = { link = "mkdLink" },
        markdownUrl = { link = "mkdURL" },
        markdownWikiLink = { link = "mkdLink" },
        ["@link_text.markdown_inline"] = { link = "mkdLink" },
        ["@markup.link.label"] = { link = "mkdLink" },
        ["@markup.link.url"] = { link = "mkdURL" },


        mkdListItem = { fg = "${cyan}" },
        markdownListMarker = { fg = "${cyan}" },
        ["@markup.list"] = { link = "markdownListMarker" },
        mkdListItemCheckbox = { fg = "${green}" },
        markdownCheckboxCanceled = { fg = "${comment}", style = "strikethrough" },
        markdownCheckboxPostponed = { fg = "${comment}" },

        markdownTag = { fg = "${comment}" },
        doneTag = { fg = "${comment}", italic = true },
        highPrioTask = { fg = "${red}", bold = true },
        TSPunctSpecial = { fg = "${red}" },
        markdownTSTitle = { fg = "${cyan}", bold = true },

        htmlH1 = { fg = "${yellow}", bold = true },
        htmlH2 = { fg = "${yellow}", bold = true },
        htmlH3 = { fg = "${yellow}" },
        htmlH4 = { fg = "${green}", italic = true },
        htmlH5 = { fg = "${green}", italic = true },
        htmlH6 = { fg = "${green}", italic = true },
        ["@markup.heading.1"] = { link = "htmlH1" },
        markdownH1 = { link = "htmlH1" },
        ["@markup.heading.2"] = { link = "htmlH2" },
        markdownH2 = { link = "htmlH2" },
        ["@markup.heading.3"] = { link = "htmlH3" },
        markdownH3 = { link = "htmlH3" },
        ["@markup.heading.4"] = { link = "htmlH4" },
        markdownH4 = { link = "htmlH4" },
        ["@markup.heading.5"] = { link = "htmlH5" },
        markdownH5 = { link = "htmlH5" },
        ["@markup.heading.6"] = { link = "htmlH6" },
        markdownH6 = { link = "htmlH6" },

        htmlBold = { fg = "#ffffff", bold = true },
        markdownBold = { link = "htmlBold" },
        ["@markup.strong"] = { link = "htmlBold" },


        htmlItalic = { fg = "#eeeeee", italic = true },
        markdownItalic = { link = "htmlItalic" },
        ["@markup.italic"] = { link = "htmlItalic" },

        htmlBoldItalic = { fg = "#ffffff", bold = true, italic = true },
        markdownBoldItalic = { link = "htmlBoldItalic" },

        ["@markup.underline"] = { underline = true },

        markdownStrikethrough = { fg = "${comment}", style = "strikethrough" },
        ["@strikethrough.markdown_inline"] = { link = "markdownStrikethrough" },
        ["@markup.strikethrough"] = { link = "markdownStrikethrough" },

        SpellBad = { style = "undercurl", sp = "${red}" },
        SpellCap = { style = "undercurl", sp = "${cyan}" },
        SpellRare = { style = "undercurl", sp = "Magenta" },
        SpellLocal = { style = "undercurl", sp = "${cyan}" },
        MatchParen = { bg = "#555555", italic = true },
        IndentBlanklineChar = { fg = "#444444" },
        -- Todo                                       = { fg = "#282c34", bg = "${highlight}", bold = true },
        VertSplit = { fg = "#202020", bg = "#606060" },
        Folded = { fg = "#c0c8d0", bg = "#384058" },
        ["@comment.markdown"] = { fg = "${comment}" },
        ["@field.markdown_inline"] = { fg = "${purple}" },
        ["@markup.raw"] = { fg = "${green}" },
        ["@markup.raw.block"] = { fg = "${green}" },


        ["@tag"] = { fg = "${comment}" },
        ["@block_quote.markdown"] = { fg = "${purple}", italic = true },
        -- ["@parameter.markdown_inline"] = { fg = theme.palette.fg },
        ["@punctuation.special.markdown"] = { fg = "${cyan}" },
        ["@punctuation.delimiter.markdown_inline"] = { fg = "${orange}" },

        ["@markup.list.unchecked"] = { fg = "#ffffff", bg = "", bold = true },

        ["@markup.list.checked"] = { fg = "${green}", bold = true },

        -- TelescopeBorder = {
        --   fg = "${telescope_results}",
        --   bg = "${telescope_results}"
        -- },
        -- TelescopePromptBorder = {
        --   fg = "${telescope_prompt}",
        --   bg = "${telescope_prompt}"
        -- },
        -- TelescopePromptCounter = { fg = "${fg}" },
        -- TelescopePromptNormal = { fg = "${fg}", bg = "${telescope_prompt}" },
        -- TelescopePromptPrefix = { fg = "${purple}", bg = "${telescope_prompt}" },
        -- TelescopePromptTitle = { fg = "${telescope_prompt}", bg = "${purple}" },
        --
        -- TelescopePreviewTitle = { fg = "${telescope_results}", bg = "${green}" },
        -- TelescopeResultsTitle = {
        --   fg = "${telescope_results}",
        --   bg = "${telescope_results}"
        -- },

        -- TelescopeMatching = { fg = "${blue}" },
        -- TelescopeNormal = { bg = "#000000" },
        -- TelescopeSelection = { bg = "${telescope_prompt}" },
        -- PmenuSel = { blend = 0 },

        -- Trouble windows
        TroubleNormalNC = { bg = "#221133" },
        TroubleNormal = { bg = "#222244" },
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
        transparency = false,   -- better to let neovide define
        terminal_colors = true, -- leave terminal windows alone
        highlight_inactive_windows = true
      },
      colors = {
        onedark = {
          -- Make neovide have a more distinctive blue bg color
          bg = (vim.g.neovide and "#16233B" or "#282c34"),
          cursorline = (vim.g.neovide and "#131F34" or "#2d313b"),
          -- telescope_prompt = "#2e323a",
          -- telescope_results = "#21252d"
        },
        -- onelight = { telescope_prompt = "#f5f5f5", telescope_results = "#eeeeee" }
      }
    })
  end

  local cscheme
  if SimpleUI then
    cscheme = "ir_black"
  else
    cscheme = "onedark"
  end
  vim.cmd.colorscheme(cscheme)
end

M.defaultFontSize = function()
  if vim.fn.has('mac') == 1 then
    return "18"
  else
    return "9"
  end
end

M.isGuiRunning = function()
  return vim.fn.has('gui_running') > 0 or vim.g.neovide or vim.g.GuiLoaded ~= nil or vim.fn.has('gui') > 0
end

M.gui = function()
  vim.opt.title = true
  vim.opt.switchbuf = "useopen,usetab,newtab"
  -- vim.opt.guifont = "Liga DejaVuSansMono Nerd Font:h16"
  -- vim.opt.guifont = "FiraCode Nerd Font:h16" -- no italics
  -- if vim.loop.os_uname().sysname == "Darwin" then
  vim.opt.guifont = "Hasklug Nerd Font:h" .. M.defaultFontSize()

  if vim.g.neovide then
    vim.opt.winblend = 30 -- floating transparency amount
    vim.opt.pumblend = 30 -- popup menu transparency amount
    vim.opt.linespace = 2
    vim.g.neovide_opacity = 0.92
    -- vim.g.transparency = 0.92
    vim.g.neovide_cursor_animation_length = 0.01
    vim.g.neovide_cursor_trail_length = 0.1
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_refresh_rate = 60
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_input_macos_alt_is_meta = false
    vim.g.neovide_hide_mouse_when_typing = false
    --vim.g.neovide_background_color = "#131F34EA" --EA -- note: for green screen purposes, try "#2a2a2aea"
    vim.g.neovide_input_use_logo = true -- enable cmd key on mac; is this needed now?
    vim.g.neovide_floating_blur_amount_x = 5.0
    vim.g.neovide_floating_blur_amount_y = 5.0
  end

  vim.opt.mouse =
  "nv" -- only use mouse in normal and visual modes (notably not insert and command)
  vim.opt.mousemodel = "popup_setpos"
  -- use the system clipboard for all unnamed yank operations
  vim.opt.clipboard = "unnamedplus"
  vim.cmd([[set guioptions="gmrLae"]])

  -- nvim-qt options
  -- Disable GUI Tabline
  vim.api.nvim_exec2([[
      if exists(':GuiTabline')
          GuiTabline 0
      endif
    ]], { output = false })
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

M.programming = function(ev)
  local bufnr = ev.buf
  local mapleadernv = require("pwnvim.mappings").mapleadernv
  local mapleadernlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadern)
  local mapleadervlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleaderv)
  local mapnlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapn)
  local mapvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapv)
  local mapnviclocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapnvic)

  vim.opt.number = true
  vim.wo.number = true
  vim.wo.spell = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = true -- add indicator for current line
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.wo.foldmethod =
  "manual"                  -- seeing weird treesitter cpu spikes when folds are off
  vim.wo.foldenable = false -- zi will turn it on
  vim.wo.foldcolumn = "0"

  M.twospaceindent()

  -- Could be a performance penalty on this
  -- Will make periodic checks to see if the file changed
  vim.api.nvim_exec2([[
    augroup programming
      autocmd!
      autocmd CursorHold,CursorHoldI * silent! checktime
    augroup END
  ]], { output = false })

  -- Load direnv when we're in a programming file as we may want
  -- the nix environment provided. Run explicitly since the autocmds
  -- might not otherwise fire.
  vim.g.direnv_auto = 0
  vim.cmd('packadd direnv.vim')
  local direnvgroup = vim.api.nvim_create_augroup("direnv", { clear = true })
  -- Function below makes direnv impure by design. We need to keep the LSP servers and other nvim dependencies
  -- in our path even after direnv overwrites the path. Whatever direnv puts in place will take precedence, but
  -- we fall back to the various language tools installed with pwnvim using this hack
  local initial_path = vim.env.PATH
  vim.api.nvim_create_autocmd("User", {
    pattern = "DirenvLoaded",
    callback = function()
      if not string.find(vim.env.PATH, initial_path, 0, true) then
        vim.env.PATH = vim.env.PATH .. ":" .. initial_path
      end
    end,
    group = direnvgroup
  })
  vim.cmd('DirenvExport')

  -- commenting
  vim.cmd('packadd comment.nvim')
  require("Comment").setup()
  mapnlocal("g/", "<Plug>(comment_toggle_linewise_current)", "Toggle comments")
  mapvlocal("g/", "<Plug>(comment_toggle_linewise_visual)", "Toggle comments")
  mapleadernlocal("c<space>", "<Plug>(comment_toggle_linewise_current)", "Toggle comments")
  mapleadervlocal("c<space>", "<Plug>(comment_toggle_linewise_visual)", "Toggle comments")

  mapnviclocal("<F5>", "make", "Build program")

  vim.cmd('packadd crates.nvim')
  require("crates").setup({})

  vim.cmd('packadd todo-comments.nvim')
  require("pwnvim.plugins.todo-comments")

  local dap, dapui = require("dap"), require("dapui")
  dapui.setup()
  mapleadernlocal("dv", function()
    if dap.session() == nil then
      dap.continue()
    else
      dapui.toggle()
    end
  end
  , "Toggle dap debugger")
  mapleadervlocal("dv", dapui.eval, "dap debugger eval selection")
  local add_debugger_bindings = function()
    mapleadernv("dc", dap.continue, "Continue")
    mapleadernv("<F5>", dap.continue, "Continue")
    mapleadernv("do", dap.step_over, "Step over")
    mapleadernv("<F10>", dap.step_over, "Step over")
    mapleadernv("di", dap.step_into, "Step into")
    mapleadernv("<F11>", dap.step_into, "Step into")
    mapleadernv("du", dap.step_out, "Step up/out")
    mapleadernv("<F12>", dap.step_out, "Step up/out")
    mapleadernv("db", dap.toggle_breakpoint, "Toggle breakpoint")
    mapleadernv("dB", dap.set_breakpoint, "Set breakpoint")
    mapleadernv("dr", dap.repl.open, "Open REPL")
    mapleadernv("dl", dap.run_last, "Run last")
    mapleadernv("dh", require("dap.ui.widgets").hover, "Hover widget")
    mapleadernv("dp", require("dap.ui.widgets").preview, "Preview widget")
  end
  dap.listeners.before.attach.dapui_config = function()
    add_debugger_bindings()
    dapui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    add_debugger_bindings()
    dapui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
  end
end

return M
