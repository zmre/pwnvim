local M = {}

M.setup = function()

  vim.g.joinspaces = true
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.spell = true
  vim.wo.list = false
  -- vim.bo.formatoptions = "jcroqln"
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
  vim.wo.foldlevel = 3
  vim.wo.foldenable = true
  vim.bo.formatoptions = 'jtqlnr' -- no c (insert comment char on wrap), with r (indent)
  vim.bo.comments = 'b:>,b:*,b:+,b:-'
  vim.bo.suffixesadd = '.md'

  vim.bo.syntax = "off" -- we use treesitter exclusively on markdown now

  require('pwnvim.markdown').markdownsyntax()

  -- TODO: make all this whichkey instead

  local opts = { noremap = false, silent = true }
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(0, ...) end

  buf_set_keymap('', '<leader>m', ':silent !open -a Marked\\ 2.app "%:p"<cr>',
    opts)

  --Leave F7 at SymbolOutline which happens when zk LSP attaches
  --buf_set_keymap('', '#7', ':Toc<CR>', opts)
  --buf_set_keymap('!', '#7', '<ESC>:Toc<CR>', opts)
  --TODO: add [t ]t for navigating tasks (instead of tabs) -- but can it work between files?
  --TODO: add desc to opts
  buf_set_keymap('n', 'gl*', [[<cmd>let p=getcurpos('.')<cr>:s/^/* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]], opts)
  buf_set_keymap('v', 'gl*', [[<cmd>let p=getcurpos('.')<cr>:s/^/* /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]], opts)
  buf_set_keymap('n', 'gl>', [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>2l]], opts)
  buf_set_keymap('v', 'gl>', [[<cmd>let p=getcurpos('.')<cr>:s/^/> /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]], opts)
  buf_set_keymap('n', 'gl[', [[<cmd>let p=getcurpos('.')<cr>:s/^/* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>5l]],
    opts)
  buf_set_keymap('v', 'gl[', [[<cmd>let p=getcurpos('.')<cr>:s/^/* [ ] /<cr>:nohlsearch<cr>:call setpos('.', p)<cr>gv]],
    opts)
  --buf_set_keymap('i', '#', '<plug>(mkdx-link-compl)', opts)

  --buf_set_keymap('', '][', '<Plug>Markdown_MoveToNextSiblingHeader', opts)
  --buf_set_keymap('', '[]', '<Plug>Markdown_MoveToPreviousSiblingHeader', opts)
  --buf_set_keymap('', ']u', '<Plug>Markdown_MoveToParentHeader', opts)
  --buf_set_keymap('', ']c', '<Plug>Markdown_MoveToCurHeader', opts)
  --buf_set_keymap('', 'ge', '<Plug>Markdown_EditUrlUnderCursor', opts)
  -- Handle cmd-b for bold
  buf_set_keymap('!', '<D-b>', '****<C-O>h', opts)
  buf_set_keymap('v', '<D-b>', 'Se', opts)
  --buf_set_keymap('v', '<leader>b', 'S*gvS*', opts)
  buf_set_keymap('v', '<leader>b', 'Se', opts) -- e is an alias configured at surround setup and equal to **
  buf_set_keymap('n', '<D-b>', 'ysiwe', opts)
  buf_set_keymap('n', '<leader>b', 'ysiwe', opts)

  -- Handle cmd-i for italic
  buf_set_keymap('!', '<D-i>', [[__<C-O>h]], opts)
  buf_set_keymap('v', '<D-i>', 'S_', opts)
  buf_set_keymap('v', '<leader>i', 'S_', opts)
  buf_set_keymap('n', '<D-i>', 'ysiw_', opts)
  buf_set_keymap('n', '<leader>i', 'ysiw_', opts)

  -- Handle cmd-1 for inline code blocks (since cmd-` has special meaning already)
  buf_set_keymap('!', '<D-1>', [[``<C-O>h]], opts)
  buf_set_keymap('v', '<D-1>', 'S`', opts)
  buf_set_keymap('v', '<leader>`', 'S`', opts)
  buf_set_keymap('n', '<D-1>', 'ysiw`', opts)
  buf_set_keymap('n', '<leader>`', 'ysiw`', opts)

  -- Handle cmd-l and ,l for adding a link
  buf_set_keymap('v', '<D-l>', 'S]%a(', opts)
  buf_set_keymap('v', '<leader>l', 'S]%a(', opts)
  buf_set_keymap('n', '<D-l>', 'ysiW]%a(', opts)
  buf_set_keymap('n', '<leader>l', 'ysiW]%a(', opts)


  buf_set_keymap('i', '<tab>', "<cmd>lua require('pwnvim.markdown').indent()<cr>", opts)
  buf_set_keymap('i', '<s-tab>', "<cmd>lua require('pwnvim.markdown').outdent()<cr>", opts)

  buf_set_keymap('n', 'gt', "<cmd>lua require('pwnvim.markdown').transformUrlUnderCursorToMdLink()<cr>", opts)
  -- no idea why the lua version of adding the command is failing
  -- vim.api.nvim_buf_add_user_command(0, 'PasteUrl', function(opts) require('pwnvim.markdown').pasteUrl() end, {})
  vim.cmd("command! PasteUrl lua require('pwnvim.markdown').pasteUrl()")

  -- This is wonderful when it's working, but I sometimes get too many open files errors that seem to come from this plugin. Plus
  -- some weirdness where my entire terminal (kitty) completely hangs for a time. Especially when typing in an alt description.
  -- So, sadly, commenting out for now. 2023-01-19
  -- if vim.env.KITTY_INSTALLATION_DIR and not vim.g.neovide then
  --   vim.cmd('packadd hologram.nvim')
  --   require('hologram').setup {
  --     auto_display = true -- WIP automatic markdown image display, may be prone to breaking
  --   }
  -- end
  vim.cmd('packadd clipboard-image.nvim')
  require 'clipboard-image'.setup {
    default = {
      img_name = function()
        vim.fn.inputsave()
        local name = vim.fn.input({ prompt = "Name: " })
        vim.fn.inputrestore()
        return os.date('%Y-%m-%d') .. "-" .. name
      end,
      img_dir = { "%:p:h", "%:t:r:s?$?_attachments?" },
      img_dir_txt = "%:t:r:s?$?_attachments?",
      affix = "![](%s)",
    }
  }


  -- I have historically always used spaces for indents wherever possible including markdown
  -- Changing now to use tabs because NotePlan 3 can't figure out nested lists that are space
  -- indented and I go back and forth between that and nvim (mainly for iOS access to notes).
  -- So, for now, this is the compatibility compromise. 2022-09-27
  require('pwnvim.options').tabindent()
  require('pwnvim.options').retab() -- turn spaces to tabs when markdown file is opened
end

M.markdownsyntax = function()
  vim.api.nvim_exec([[
    " markdownWikiLink is a new region
    "syn region markdownWikiLink matchgroup=markdownLinkDelimiter start="\[\[" end="\]\]" contains=markdownUrl keepend oneline concealends
    " markdownLinkText is copied from runtime files with 'concealends' appended
    "syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\%(\_[^][]\|\[\_[^][]*\]\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
    " markdownLink is copied from runtime files with 'conceal' appended
    "syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
    " syn match markdownTag '#\w\+'
    " syn cluster markdownInline add=markdownTag
    " Edit htmlTag to ignore tags starting with a number like <2022
    " syn region htmlTag start=+<[^/0-9]+ end=+>+ fold contains=htmlTagN,htmlString,htmlArg,htmlValue,htmlTagError,htmlEvent,htmlCssDefinition,@htmlPreproc,@htmlArgCluster
    " syn match mkdListItemCheckbox /\[[xXoO\> -]\]\ze\s\+/ contained contains=mkdListItem
    let m = matchadd("bareLink", "\\<https:[a-zA-Z?&,;=$+%#/.!~':@0-9_-]*")
    " let m = matchadd("markdownCheckboxChecked", "[*-] \\[x\\] ")
    let m = matchadd("markdownCheckboxCanceled", "[*-] \\[-\\] .\\+")
    let m = matchadd("markdownCheckboxPostponed", "[*-] \\[>\\] .\\+")
    " below is because Noteplan uses capital X and default styling is a link on [X] so this will at least make it green
    let m = matchadd("@text.todo.checked", "[*-] \\[[xX]\\] ")
    let m = matchadd("markdownTag", '#\w\+')
    let m = matchadd("markdownStrikethrough", "\\~\\~[^~]*\\~\\~")
    let m = matchadd("doneTag", '@done(20[^)]*)')
    let m = matchadd("highPrioTask", "[*-] \\[ \\] .\\+!!!")
  ]], false)
end

M.indent = function()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*[*-]") then
    local ctrlt = vim.api.nvim_replace_termcodes("<C-t>", true, false, true)
    vim.api.nvim_feedkeys(ctrlt, "n", false)
    --line = "\t" .. line
    --vim.api.nvim_set_current_line(line)
    --vim.cmd("normal l")
    -- local norm_mode = vim.api.nvim_replace_termcodes("<C-o>", true, false, true)
    -- local shiftwidth = vim.bo.shiftwidth + 1
    -- vim.api.nvim_feedkeys(norm_mode .. ">>", "n", false)
    -- vim.api.nvim_feedkeys(norm_mode .. shiftwidth .. "l", "n", false)
  else
    -- send through regular tab character at current position
    vim.api.nvim_feedkeys("\t", "n", false)
  end
end

M.outdent = function()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*[*-]") then
    local ctrld = vim.api.nvim_replace_termcodes("<C-d>", true, false, true)
    vim.api.nvim_feedkeys(ctrld, "n", false)
    -- TODO: shift width is correct if at least that many characters are between us and last column
    --       but if we're on last column already, we'll auto move and compensate should be 0
    -- local col = vim.api.nvim_win_get_cursor(0)
    --local shiftwidth = vim.bo.shiftwidth
    --vim.api.nvim_feedkeys(norm_mode .. "<<", "n", false)
    --vim.api.nvim_feedkeys(norm_mode .. shiftwidth .. "h", "n", false)
  end
end

M.getTitleFor = function(url)
  local curl = require "plenary.curl"
  local res = curl.request {
    url = url,
    method = "get",
    accept = "text/html",
    raw = { "-L" } -- follow redirects
  }
  local title = ""
  if res then
    title = string.match(res.body, "<title[^>]*>([^<]+)</title>")
    if not title then
      title = string.match(res.body, "<h1[^>]*>([^<]+)</h1>")
    end
  end
  if not title then
    title = "could not get title" -- TODO: put domain here
  end
  return title
end

M.transformUrlUnderCursorToMdLink = function()
  --local url = vim.fn.expand("<cfile>")
  local url = vim.fn.expand("<cWORD>")
  local title = require("pwnvim.markdown").getTitleFor(url)
  vim.cmd("normal! ciW[" .. title .. "](" .. url .. ")")
end

M.pasteUrl = function()
  local url = vim.fn.getreg('*')
  local title = require("pwnvim.markdown").getTitleFor(url)
  vim.cmd("normal! i[" .. title .. "](" .. url .. ")")
end

return M
