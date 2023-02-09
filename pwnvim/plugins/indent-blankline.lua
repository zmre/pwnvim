if not SimpleUI then
  vim.g.indentLine_enabled = 1
  vim.g.indent_blankline_char = '┊'
  -- vim.g.indent_blankline_char = "▏"
  vim.g.indent_blankline_filetype_exclude = { 'help', 'packer' }
  vim.g.indent_blankline_buftype_exclude = { 'terminal', 'nofile' }
  vim.g.indent_blankline_char_highlight = 'LineNr'
  vim.g.indent_blankline_show_trailing_blankline_indent = false
  vim.g.indent_blankline_filetype_exclude = {
    "help", "startify", "dashboard", "packer", "neogitstatus", "NvimTree",
    "Trouble"
  }
  vim.g.indent_blankline_use_treesitter = true
  vim.g.indent_blankline_show_current_context = true
  vim.g.indent_blankline_context_patterns = {
    "class", "return", "function", "method", "^if", "^while", "jsx_element",
    "^for", "^object", "^table", "block", "arguments", "if_statement",
    "else_clause", "jsx_element", "jsx_self_closing_element",
    "try_statement", "catch_clause", "import_statement", "operation_type"
  }
  -- HACK: work-around for https://github.com/lukas-reineke/indent-blankline.nvim/issues/59
  vim.wo.colorcolumn = "99999"

  require('indent_blankline').setup({
    show_current_context = true,
    use_treesitter = true,
    buftype_exclude = { 'terminal' },
    filetype_exclude = { 'help', 'markdown' },
  })
end
