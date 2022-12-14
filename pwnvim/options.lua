local M = {}

M.defaults = function()
  local opt = vim.opt
  local simpleUI = os.getenv("SIMPLEUI")

  -- disable builtin vim plugins
  vim.g.loaded_gzip = 0
  vim.g.loaded_tar = 0
  vim.g.loaded_tarPlugin = 0
  vim.g.loaded_zipPlugin = 0
  vim.g.loaded_2html_plugin = 0
  vim.g.loaded_netrw = 0
  vim.g.loaded_netrwPlugin = 0
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
  -- vim.g.do_filetype_lua = 1 -- Activate the Lua filetype detection mechanism
  -- vim.g.did_load_filetypes = 0 -- Disable filetype.vim detection mechanism
  -- vim.cmd([[
  -- let g:mkdx#settings     = { 'highlight': { 'enable': 1 },
  --                       \ 'enter': { 'enable': 1, 'shift': 1, 'o': 1, 'shifto': 1 },
  --                       \ 'tokens': { 'strike': '~~', 'list': '*' },
  --                       \ 'map': { 'enable': 0 },
  --                       \ 'gf_on_steroids': 1,
  --                       \ 'conceal': 1,
  --                       \ 'links': { 'external': { 'enable': 0 }, 'fragment': { 'complete': 1 } },
  --                       \ 'toc': { 'text': 'Table of Contents', 'update_on_write': 0 },
  --                       \ 'fold': { 'enable': 1 } }
  -- ]])

  opt.swapfile = false
  opt.spell = true
  opt.spelllang = "en_us"
  opt.ruler = true -- show the cursor position all the time
  opt.cursorline = true -- add indicator for current line
  opt.secure = true -- don't execute shell cmds in .vimrc not owned by me
  opt.history = 50 -- keep 50 lines of command line history
  opt.shell = "zsh"
  opt.modelines = 0 -- Don't allow vim settings embedded in text files for security reasons
  opt.showcmd = true -- display incomplete commands
  opt.showmode = true -- display current mode
  opt.backup = false
  opt.writebackup = true
  opt.backupcopy = "auto"
  opt.hidden = true
  opt.cf = true -- jump to errors based on error files
  opt.listchars = "tab:⇥ ,trail:␣,extends:⇉,precedes:⇇,nbsp:·"
  opt.list = true -- render special chars (tabs, trails, ...)
  opt.ttyfast = true
  opt.expandtab = true
  opt.splitbelow = true -- allow splits below
  opt.splitright = true -- and to the right
  opt.dictionary = opt.dictionary +
      { '/usr/share/dict/words', '~/.aspell.english.pws' }
  opt.complete = opt.complete + { 'k', ']' }
  opt.complete = opt.complete - { 'i' }
  opt.encoding = "utf-8"
  opt.backspace = "indent,eol,start" -- allow backspacing over everything in insert mode
  opt.joinspaces = false -- don't insert two spaces after sentences on joins
  opt.binary = false
  opt.display = "lastline"
  opt.viewoptions = "folds,cursor,unix,slash" -- better unix / windows compatibility
  opt.shortmess = "filnxtToSAcOF"
  opt.foldnestmax = 5

  -- wrapping
  opt.wrap = true
  opt.sidescroll = 2 -- min number of columns to scroll from edge
  opt.scrolloff = 8 -- when 4 away from edge start scrolling
  opt.sidescrolloff = 8 -- keep cursor one col from end of line
  opt.textwidth = 0
  opt.breakindent = true
  opt.showbreak = "» "
  opt.breakat = opt.breakat - { '/', '*', '_', '`' }
  opt.linebreak = true -- wraps on word boundaries but only if nolist is set

  -- Make tabs be spaces of 4 characters by default
  opt.tabstop = 4
  opt.shiftwidth = 4
  opt.softtabstop = 4
  opt.expandtab = true -- turn tabs to spaces by default

  opt.autoindent = true -- autoindent to same level as previous line
  opt.smartindent = true -- indent after { and cinwords words
  opt.smartcase = true -- intelligently ignore case in searches
  opt.ignorecase = true -- default to not being case sensitive
  opt.smarttab = true
  opt.icm = "nosplit" -- show substitutions as you type
  opt.hlsearch = true
  opt.updatetime = 250 -- Decrease update time
  vim.wo.signcolumn = 'yes'
  opt.visualbell = true
  opt.autoread = true -- auto reload files changed on disk if not changed in buffer
  opt.cursorline = false
  opt.ttyfast = true
  opt.formatoptions = 'jcroqlt' -- t=text, c=comments, q=format with "gq"
  opt.showmatch = true -- auto hilights matching bracket or paren
  opt.nrformats = opt.nrformats - { 'octal' }
  opt.shiftround = true
  opt.ttimeout = true
  opt.ttimeoutlen = 50
  opt.fileformats = "unix,dos,mac"
  opt.matchpairs = "(:),{:},[:],<:>"
  opt.number = false
  opt.relativenumber = false
  opt.completeopt = "menu,menuone,noselect" -- needed for autocompletion stuff
  opt.conceallevel = 2
  opt.fileencoding = "utf-8"

  -- Globals
  vim.g.vimsyn_embed = 'l' -- Highlight Lua code inside .vim files
  -- vim.g.polyglot_disabled = { 'sensible', 'autoindent' } -- preserve in case I want to bring back polyglot
  vim.g.foldlevelstart = 3

  -- map the leader key
  vim.api.nvim_set_keymap('n', ',', '', {})
  vim.g.mapleader = ',' -- Namespace for custom shortcuts

  if simpleUI ~= "1" then
    vim.o.termguicolors = true
  else
    vim.o.termguicolors = false
  end
  vim.o.background = "dark"

  require("onedarkpro").setup({
    -- Call :OnedarkproCache if you make changes below and to speed startups
    caching = true,
    highlights = {
      mkdLink                                    = { fg = "${blue}", style = "underline" },
      bareLink                                   = { fg = "${blue}", style = "underline" },
      mkdURL                                     = { fg = "${green}", style = "underline" },
      mkdInlineURL                               = { fg = "${blue}", style = "underline" },
      mkdListItem                                = { fg = "${cyan}" },
      markdownListMarker                         = { fg = "${cyan}" },
      mkdListItemCheckbox                        = { fg = "${green}" },
      -- markdownCheckbox                           = { fg = "${purple}" },
      --markdownCheckboxUnchecked                  = { fg = "${purple}" },
      markdownCheckboxChecked                    = { fg = "${green}" },
      markdownCheckboxCanceled                   = { fg = "${comment}", style = "strikethrough" },
      markdownCheckboxPostponed                  = { fg = "${comment}" },
      markdownStrikethrough                      = { fg = "${comment}", style = "strikethrough" },
      markdownTag                                = { fg = "${comment}" },
      -- mkdLinkTitle
      -- mkdID
      -- mkdDelimiter
      -- mkdInlineURL
      -- mkdCode
      -- mkdFootnote
      -- mkdMath
      -- htmlLink
      TSURI                                      = { fg = "${blue}", style = "underline" },
      TSPunctSpecial                             = { fg = "${red}" },
      markdownTSTitle                            = { fg = "${cyan}", style = "bold" },
      markdownAutomaticLink                      = { fg = "${blue}", style = "underline" },
      markdownLink                               = { fg = "${green}", style = "underline" },
      markdownLinkText                           = { fg = "${blue}", style = "underline" },
      markdownUrl                                = { fg = "${green}", style = "underline" },
      markdownWikiLink                           = { fg = "${blue}", style = "underline" },
      markdownH1                                 = { fg = "${yellow}", style = "bold" },
      markdownH2                                 = { fg = "${yellow}", style = "bold" },
      markdownH3                                 = { fg = "${yellow}" },
      markdownH4                                 = { fg = "${green}", style = "italic" },
      markdownH5                                 = { fg = "${green}", style = "italic" },
      markdownH6                                 = { fg = "${green}", style = "italic" },
      htmlH1                                     = { fg = "${yellow}", style = "bold" },
      htmlH2                                     = { fg = "${yellow}", style = "bold" },
      htmlH3                                     = { fg = "${yellow}" },
      htmlH4                                     = { fg = "${green}", style = "italic" },
      htmlH5                                     = { fg = "${green}", style = "italic" },
      htmlH6                                     = { fg = "${green}", style = "italic" },
      markdownBold                               = { fg = "#ffffff", style = "bold" },
      htmlBold                                   = { fg = "#ffffff", style = "bold" },
      markdownItalic                             = { fg = "#eeeeee", style = "italic" },
      htmlItalic                                 = { fg = "#eeeeee", style = "italic" },
      markdownBoldItalic                         = { fg = "#ffffff", style = "bold,italic" },
      htmlBoldItalic                             = { fg = "#ffffff", style = "bold,italic" },
      SpellBad                                   = { style = "undercurl", sp = "${red}" },
      SpellCap                                   = { style = "undercurl", sp = "${cyan}" },
      SpellRare                                  = { style = "undercurl", sp = "Magenta" },
      SpellLocal                                 = { style = "undercurl", sp = "${cyan}" },
      IndentBlanklineChar                        = { fg = "#444444" },
      Todo                                       = { fg = "#282c34", bg = "${highlight}", style = "bold" },
      VertSplit                                  = { fg = "#202020", bg = "#606060" },
      Folded                                     = { fg = "#c0c8d0", bg = "#384058" },
      ["@comment.markdown"]                      = { fg = "${comment}" },
      ["@field.markdown_inline"]                 = { fg = "${purple}" },
      ["@text.literal.markdown_inline"]          = { fg = "${green}" },
      ["@text.reference.markdown_inline"]        = { fg = "${blue}", style = "underline" },
      ["@text.underline"]                        = { style = "underline" },
      ["@text.strong.markdown_inline"]           = { fg = "#ffffff", style = "bold" },
      ["@text.emphasis.markdown_inline"]         = { fg = "#eeeeee", style = "italic" },
      ["@strikethrough.markdown_inline"]         = { fg = "${comment}", style = "strikethrough" },
      ["@tag"]                                   = { fg = "${comment}" },
      ["@block_quote.markdown"]                  = { fg = "${purple}", style = "italic" },
      ["@text.title.markdown"]                   = { fg = "${yellow}", style = "bold" },
      -- ["@parameter.markdown_inline"] = { fg = theme.palette.fg },
      ["@punctuation.special.markdown"]          = { fg = "${cyan}" },
      ["@punctuation.delimiter.markdown_inline"] = { fg = "${orange}" },
      ["@text.uri.markdown_inline"]              = { fg = "${blue}" },

      TelescopeBorder        = {
        fg = "${telescope_results}",
        bg = "${telescope_results}",
      },
      TelescopePromptBorder  = {
        fg = "${telescope_prompt}",
        bg = "${telescope_prompt}",
      },
      TelescopePromptCounter = { fg = "${fg}" },
      TelescopePromptNormal  = { fg = "${fg}", bg = "${telescope_prompt}" },
      TelescopePromptPrefix  = {
        fg = "${purple}",
        bg = "${telescope_prompt}",
      },
      TelescopePromptTitle   = {
        fg = "${telescope_prompt}",
        bg = "${purple}",
      },

      TelescopePreviewTitle = {
        fg = "${telescope_results}",
        bg = "${green}",
      },
      TelescopeResultsTitle = {
        fg = "${telescope_results}",
        bg = "${telescope_results}",
      },

      TelescopeMatching = { fg = "${blue}" },
      TelescopeNormal = { bg = "${telescope_results}" },
      TelescopeSelection = { bg = "${telescope_prompt}" },
    },
    styles = { -- Choose from "bold,italic,underline"
      virtual_text = "italic", -- Style that is applied to virtual text
    },
    plugins = {
      all = true
    },
    options = {
      bold = simpleUI ~= "1",
      italic = simpleUI ~= "1",
      underline = simpleUI ~= "1",
      undercurl = simpleUI ~= "1",
      cursorline = true,
      transparency = false,
      terminal_colors = false,
      highlight_inactive_windows = true
    },
    colors = {
      onedark = {
        telescope_prompt = "#2e323a",
        telescope_results = "#21252d",
      },
      onelight = {
        telescope_prompt = "#f5f5f5",
        telescope_results = "#eeeeee",
      },
    },
  })
  vim.api.nvim_exec([[
    colorscheme onedark
    filetype plugin indent on
    syntax on
    syntax sync minlines=5000
    "unlet did_load_filetypes
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
  if vim.fn.has('mac') then
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
  -- vim.cmd('%retab!')
end

M.programming = function()
  vim.opt.number = true
  vim.wo.number = true
  vim.wo.spell = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = true -- add indicator for current line

  M.twospaceindent()
  -- Setup Ctrl and Cmd-/ to toggle comments
  vim.api.nvim_buf_set_keymap(0, 'n', '<D-/>',
    '<Plug>kommentary_line_default', {})
  vim.api.nvim_buf_set_keymap(0, 'v', '<D-/>',
    '<Plug>kommentary_visual_default', {})
  vim.api.nvim_buf_set_keymap(0, 'i', '<D-/>', '<C-O>,c<space>', {})
  vim.api.nvim_buf_set_keymap(0, 'n', '<C-/>',
    '<Plug>kommentary_line_default', {})
  vim.api.nvim_buf_set_keymap(0, 'v', '<C-/>',
    '<Plug>kommentary_visual_default', {})
  vim.api.nvim_buf_set_keymap(0, 'i', '<C-/>', '<C-O>,c<space>', {})

  -- Could be a performance penalty on this
  -- Will make periodic checks to see if the file changed
  vim.api.nvim_exec([[
    augroup programming
      autocmd!
      autocmd CursorHold,CursorHoldI * silent! checktime
    augroup END
  ]], false)

end

return M
