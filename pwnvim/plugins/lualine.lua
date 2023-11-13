require('lualine').setup {
  options = {
    theme = 'papercolor_light',
    icons_enabled = not SimpleUI,
    component_separators = { left = SimpleUI and '>' or '', right = SimpleUI and '<' or '' },
    disabled_filetypes = { 'pager' },
    section_separators = { left = SimpleUI and '>' or '', right = SimpleUI and '<' or '' },
    globalstatus = true
  },
  extensions = { 'quickfix', 'fugitive' },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = { 'filename' },
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress', 'location' },
    lualine_z = {
      --{
      -- require("noice").api.statusline.mode.get,
      -- cond = require("noice").api.statusline.mode.has,
      --color = { fg = "#ff9e64" },
      --},
      {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        -- displays diagnostics from defined severity
        sections = { 'error', 'warn' },
        color_error = "#E06C75",
        color_warn = "#E5C07B"
      }
    }
  }
}
