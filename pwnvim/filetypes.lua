local M = {}

M.config = function()
  vim.api.nvim_exec([[
    augroup filetypes
      autocmd!
      autocmd BufRead *.sbt             setlocal filetype=scala
      autocmd BufRead ~/mail/*          setlocal filetype=mail
      autocmd BufRead /tmp/mutt*        setlocal filetype=mail
      autocmd BufRead ~/.signature*     setlocal filetype=mail
      autocmd BufRead ~/.mutt/*         setlocal filetype=muttrc
      autocmd BufRead ~/.sawfish/custom setlocal filetype=lisp
      autocmd BufRead *.*html*          setlocal filetype=html
      autocmd BufRead *.css*            setlocal filetype=css
      autocmd BufRead *.rss             setlocal filetype=xml
      autocmd BufRead *.mc              setlocal filetype=mason
      autocmd BufRead *.fish            setlocal filetype=fish

      autocmd FileType c lua require('pwnvim.options').programming()
      autocmd FileType ruby lua require('pwnvim.options').programming()
      autocmd FileType rust lua require('pwnvim.filetypes').rust()
      autocmd FileType php lua require('pwnvim.options').programming()
      autocmd FileType php3 lua require('pwnvim.options').programming()
      autocmd FileType perl lua require('pwnvim.options').programming()
      autocmd FileType python lua require('pwnvim.options').programming()
      autocmd FileType mason lua require('pwnvim.options').programming()
      autocmd FileType vim lua require('pwnvim.options').programming()
      autocmd FileType lua lua require('pwnvim.options').programming()
      autocmd FileType sh lua require('pwnvim.options').programming()
      autocmd FileType zsh lua require('pwnvim.options').programming()
      autocmd FileType scala lua require('pwnvim.options').programming()
      autocmd FileType javascript lua require('pwnvim.options').programming()
      autocmd FileType javascriptreact lua require('pwnvim.options').programming()
      autocmd FileType typescript lua require('pwnvim.options').programming()
      autocmd FileType typescriptreact lua require('pwnvim.options').programming()
      autocmd FileType md lua require('pwnvim.filetypes').markdown()
      autocmd FileType markdown lua require('pwnvim.filetypes').markdown()
      autocmd FileType vimwiki lua require('pwnvim.filetypes').markdown()
      autocmd FileType html lua require('pwnvim.options').programming()
      autocmd FileType svelte lua require('pwnvim.options').programming()
      autocmd FileType css lua require('pwnvim.options').programming()
      autocmd FileType xml lua require('pwnvim.filetypes').lua()
    augroup END
  ]], false)
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
