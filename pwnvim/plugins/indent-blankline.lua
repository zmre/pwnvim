if not SimpleUI then
  require('indent_blankline').setup({
    enabled = true,
    show_current_context = true,
    use_treesitter = true,
    use_treesitter_scope = true,
    filetype_exclude = { 'help', 'markdown', 'nofile', 'help', 'packer', 'Trouble',
      "startify", "dashboard", "neogitstatus", "lspinfo", "checkhealth", "man", "", "NvimTree",
    },
    buftype_exclude = { 'terminal', 'help', 'markdown', 'nofile', 'help', 'quickfix', 'prompt' },
    char = '┊',
    context_char = "▏",
    context_highlight_list = { 'VertSplit' },
    show_trailing_blankline_indent = false,
  })
end
