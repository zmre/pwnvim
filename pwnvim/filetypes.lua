local M = {}

M.config = function()
  local filetypes = vim.api.nvim_create_augroup("filetypes", {clear = true})
  local autocmd = vim.api.nvim_create_autocmd
  -- Function below makes direnv impure by design. We need to keep the LSP servers and other nvim dependencies
  -- in our path even after direnv overwrites the path. Whatever direnv puts in place will take precedence, but
  -- we fall back to the various language tools installed with pwnvim using this hack
  local initial_path = vim.env.PATH
  autocmd("User DirenvLoaded", {
    callback = function()
      if not string.find(vim.env.PATH, initial_path, 0, true) then
        vim.env.PATH = vim.env.PATH .. ":" .. initial_path
      end
    end,
    group = filetypes
  })

  autocmd("BufRead", {
    pattern = {"*.markdown", "*.md"},
    command = "setlocal filetype=markdown",
    group = filetypes
  })
  autocmd("BufRead", {
    pattern = {"*.sbt"},
    command = "setlocal filetype=scala",
    group = filetypes
  })
  autocmd("BufRead", {
    pattern = {"~/mail/*", "/tmp/mutt*", "~/.signature*"},
    command = "setlocal filetype=mail",
    group = filetypes
  })
  autocmd("BufRead", {
    pattern = {"~/.mutt/*"},
    command = "setlocal filetype=muttrc",
    group = filetypes
  })
  autocmd("BufRead", {
    pattern = {"*.*html*"},
    command = "setlocal filetype=html",
    group = filetypes
  })
  autocmd("BufRead", {
    pattern = {"*.css*"},
    command = "setlocal filetype=css",
    group = filetypes
  })
  autocmd("BufRead", {
    pattern = {"*.rss"},
    command = "setlocal filetype=xml",
    group = filetypes
  })
  autocmd("BufRead", {
    pattern = {"flake.lock"},
    command = "setlocal filetype=json",
    group = filetypes
  })

  autocmd("FileType", {
    pattern = {"sql", "mysql", "plsql"},
    callback = function()
      require('cmp').setup.buffer({
        enabled = true,
        sources = {{name = 'vim-dadbod-completion'}}
      })
    end,
    group = filetypes
  })
  autocmd("FileType", {
    pattern = {
      "c", "ruby", "php", "php3", "perl", "python", "mason", "vim", "sh", "zsh",
      "scala", "javascript", "javascriptreact", "typescript", "typescriptreact",
      "html", "svelte", "css", "nix"
    },
    callback = function() require('pwnvim.options').programming() end,
    group = filetypes
  })
  autocmd("FileType", {
    pattern = {"lua", "xml"},
    callback = function() require('pwnvim.filetypes').lua() end,
    group = filetypes
  })
  autocmd("FileType", {
    pattern = {"md", "markdown", "vimwiki"},
    callback = function() require('pwnvim.markdown').setup() end,
    group = filetypes
  })
  autocmd("FileType", {
    pattern = {"rust"},
    callback = function() require('pwnvim.filetypes').rust() end,
    group = filetypes
  })
  autocmd("FileType", {
    pattern = {"Outline"},
    command = "setlocal nospell",
    group = filetypes
  })

  autocmd("TermOpen",
          {pattern = {"*"}, command = "setlocal nospell", group = filetypes})
  -- Run when page pager is invoked
  autocmd('User', {
    pattern = {'PageOpen', 'PageOpenFile'},
    group = filetypes,
    callback = function() require('pwnvim.filetypes').page() end
  })
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
  require('pwnvim.options').twospaceindent()
end

M.page = function()
  -- disable status bar -- handled in config
  -- map space to ctrl-f
  vim.api.nvim_buf_set_keymap(0, 'n', '<space>', '<PageDown>', {})
end

M.reloadFile = function()
  require("plenary.reload").reload_module '%'
  vim.cmd("luafile %")
end

return M
