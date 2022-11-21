local M = {}

M.config = function()
  local filetypes = vim.api.nvim_create_augroup("filetypes", { clear = true })
  local autocmd = vim.api.nvim_create_autocmd
  autocmd("FileType",
    { pattern = { "c", "ruby", "php", "php3", "perl", "python", "mason", "vim", "sh", "zsh", "scala", "javascript",
      "javascriptreact", "typescript", "typescriptreact", "html", "svelte", "css" },
      callback = function() require('pwnvim.options').programming() end, group = filetypes })
  autocmd("FileType",
    { pattern = { "lua", "xml" }, callback = function() require('pwnvim.filetypes').lua() end, group = filetypes })
  autocmd("FileType",
    { pattern = { "md", "Markdown", "vimwiki" }, callback = function() require('pwnvim.filetypes').markdown() end,
      group = filetypes })
  autocmd("FileType",
    { pattern = { "rust" }, callback = function() require('pwnvim.filetypes').rust() end, group = filetypes })
  autocmd("FileType",
    { pattern = { "Outline" }, command = "setlocal nospell", group = filetypes })

  autocmd("BufRead", { pattern = { "*.sbt" }, command = "setlocal filetype=scala", group = filetypes })
  autocmd("BufRead",
    { pattern = { "~/mail/*", "/tmp/mutt*", "~/.signature*" }, command = "setlocal filetype=mail", group = filetypes })
  autocmd("BufRead", { pattern = { "~/.mutt/*" }, command = "setlocal filetype=muttrc", group = filetypes })
  autocmd("BufRead", { pattern = { "*.*html*" }, command = "setlocal filetype=html", group = filetypes })
  autocmd("BufRead", { pattern = { "*.css*" }, command = "setlocal filetype=css", group = filetypes })
  autocmd("BufRead", { pattern = { "*.rss" }, command = "setlocal filetype=xml", group = filetypes })

  autocmd("TermOpen", { pattern = { "*" }, command = "setlocal nospell", group = filetypes })
end

M.rust = function()
  require('pwnvim.options').programming()
  require('pwnvim.options').fourspaceindent()
  vim.bo.makeprg = "cargo"
  vim.cmd("compiler cargo")
  vim.g.rustfmt_autosave = 1
  vim.g.rust_fold = 1
  vim.api.nvim_exec([[
    augroup rustquickfix
      autocmd!
      autocmd BufReadPost quickfix setlocal foldmethod=expr
      autocmd BufReadPost quickfix setlocal foldexpr=getline(v:lnum)[0:1]=='\|\|'
      autocmd BufEnter quickfix setlocal foldexpr=getline(v:lnum)[0:1]=='\|\|'
      autocmd BufReadPost quickfix setlocal foldlevel=0
    augroup END
  ]], false)
end

M.c = function()
  require('pwnvim.options').programming()
  require('pwnvim.options').fourspaceindent()
  vim.bo.makeprg = "make"
end

M.lua = function()
  require('pwnvim.options').programming()
  require('pwnvim.options').fourspaceindent()
end

M.markdown = function()
  -- I have historically always used spaces for indents wherever possible including markdown
  -- Changing now to use tabs because NotePlan 3 can't figure out nested lists that are space
  -- indented and I go back and forth between that and nvim. So, for now, this is the compatibility
  -- compromise. 2022-09-27
  require('pwnvim.options').tabindent()
  vim.g.joinspaces = true
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.spell = true
  vim.wo.list = false
  -- vim.bo.formatoptions = "jcroqln"
  vim.wo.foldmethod = "expr"
  vim.wo.foldlevel = 3
  vim.wo.foldenable = true

  local opts = { noremap = false, silent = true }
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(0, ...) end

  buf_set_keymap('', '<leader>M', '<Plug>MarkdownPreview', opts)
  -- buf_set_keymap('', '<leader>M', '<Plug>MarkdownPreviewStop', opts)
  buf_set_keymap('', '<leader>m', ':silent !open -a Marked\\ 2.app "%:p"<cr>',
    opts)

  buf_set_keymap('', '#7', ':Toc<CR>', opts)
  buf_set_keymap('!', '#7', '<ESC>:Toc<CR>', opts)
  buf_set_keymap('', ']d', ':silent VimwikiDiaryNextDay<CR>', opts)
  buf_set_keymap('', '[d', ':silent VimwikiDiaryPrevDay<CR>', opts)

  buf_set_keymap('', ']]', '<Plug>Markdown_MoveToNextHeader', opts)
  buf_set_keymap('', '[[', '<Plug>Markdown_MoveToPreviousHeader', opts)
  buf_set_keymap('', '][', '<Plug>Markdown_MoveToNextSiblingHeader', opts)
  buf_set_keymap('', '[]', '<Plug>Markdown_MoveToPreviousSiblingHeader', opts)
  buf_set_keymap('', ']u', '<Plug>Markdown_MoveToParentHeader', opts)
  buf_set_keymap('', ']c', '<Plug>Markdown_MoveToCurHeader', opts)
  buf_set_keymap('', 'ge', '<Plug>Markdown_EditUrlUnderCursor', opts)
  -- Handle cmd-b for bold
  buf_set_keymap('!', '<D-b>', '****<C-O>h', opts)
  buf_set_keymap('v', '<D-b>', 'S*gvS*', opts)
  buf_set_keymap('v', '<leader>b', 'S*gvS*', opts)
  buf_set_keymap('n', '<D-b>', 'ysiw*lysiw*h', opts)
  buf_set_keymap('n', '<leader>b', 'ysiw*lysiw*h', opts)

  -- Handle cmd-i for italic
  buf_set_keymap('!', '<D-i>', [[__<C-\><C-O>h]], opts)
  buf_set_keymap('v', '<D-i>', 'S_', opts)
  buf_set_keymap('v', '<leader>i', 'S_', opts)
  buf_set_keymap('n', '<D-i>', 'ysiw_', opts)
  buf_set_keymap('n', '<leader>i', 'ysiw_', opts)

  -- Handle cmd-1 for inline code blocks (since cmd-` has special meaning already)
  buf_set_keymap('!', '<D-1>', [[``<C-\><C-O>h]], opts)
  buf_set_keymap('v', '<D-1>', 'S`', opts)
  buf_set_keymap('v', '<leader>`', 'S`', opts)
  buf_set_keymap('n', '<D-1>', 'ysiw`', opts)
  buf_set_keymap('n', '<leader>`', 'ysiw`', opts)

  -- Handle cmd-l and ,l for adding a link
  buf_set_keymap('v', '<D-l>', 'S]%a(', opts)
  buf_set_keymap('v', '<leader>l', 'S]%a(', opts)
  buf_set_keymap('n', '<D-l>', 'ysiW]%a(', opts)
  buf_set_keymap('n', '<leader>l', 'ysiW]%a(', opts)

  buf_set_keymap('', '#7', ':Toc<CR>', opts)
  buf_set_keymap('!', '#7', '<ESC>:Toc<CR>', opts)
end

return M
