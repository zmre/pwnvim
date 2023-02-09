require('lualine').setup {
  options = {
    theme = 'papercolor_light',
    icons_enabled = not SimpleUI,
    component_separators = { left = SimpleUI and '>' or '', right = SimpleUI and '<' or '' },
    disabled_filetypes = { 'pager' },
    section_separators = { left = SimpleUI and '>' or '', right = SimpleUI and '<' or '' }
  },
  extensions = { 'quickfix', 'nvim-tree', 'fugitive' },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = { 'nvim-tree', 'filename' },
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = {
      {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        -- displays diagnostics from defined severity
        sections = { 'error', 'warn' }, -- 'info', 'hint'},}}
        color_error = "#E06C75", -- changes diagnostic's error foreground color
        color_warn = "#E5C07B"
      }
    }
  }
}
